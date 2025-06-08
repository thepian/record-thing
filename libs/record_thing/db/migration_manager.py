#!/usr/bin/env python3
"""
Enhanced Migration Manager for RecordThing
Handles backward-compatible database migrations and backup restoration
"""

import sqlite3
import json
import hashlib
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass, asdict
from datetime import datetime
import logging
import shutil

logger = logging.getLogger(__name__)


@dataclass
class MigrationInfo:
    version: int
    description: str
    sql_hash: str
    swift_hash: Optional[str]
    applied_at: str
    rollback_sql: Optional[str]
    compatibility_version: int  # Minimum version for backup compatibility


@dataclass
class BackupInfo:
    version: int
    schema_hash: str
    tables: List[str]
    compatibility_level: str  # 'compatible', 'migration_required', 'incompatible'
    created_at: Optional[str] = None


@dataclass
class MigrationStep:
    sql: str
    description: str
    rollback_sql: Optional[str] = None
    is_breaking: bool = False


class MigrationManager:
    """Enhanced migration manager with backup compatibility"""
    
    def __init__(self, db_path: Path):
        self.db_path = db_path
        self.sql_dir = Path(__file__).parent
        
    def get_current_schema_version(self) -> int:
        """Get the current schema version from database"""
        if not self.db_path.exists():
            return 0
            
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            
            # Check if schema_migrations table exists
            cursor.execute("""
                SELECT name FROM sqlite_master 
                WHERE type='table' AND name='schema_migrations'
            """)
            
            if not cursor.fetchone():
                return 0
                
            # Get latest migration version
            cursor.execute("SELECT COALESCE(MAX(version), 0) FROM schema_migrations")
            return cursor.fetchone()[0]
    
    def calculate_schema_hash(self, db_path: Path) -> str:
        """Calculate hash of database schema for change detection"""
        with sqlite3.connect(db_path) as conn:
            cursor = conn.cursor()
            
            # Get all table schemas
            cursor.execute("""
                SELECT sql FROM sqlite_master 
                WHERE type='table' AND name NOT LIKE 'sqlite_%'
                ORDER BY name
            """)
            
            schemas = [row[0] for row in cursor.fetchall() if row[0]]
            schema_text = '\n'.join(schemas)
            
            return hashlib.sha256(schema_text.encode()).hexdigest()[:16]
    
    def detect_backup_schema_version(self, backup_path: Path) -> BackupInfo:
        """Analyze backup database to determine schema version and compatibility"""
        if not backup_path.exists():
            raise FileNotFoundError(f"Backup file not found: {backup_path}")
            
        with sqlite3.connect(backup_path) as conn:
            cursor = conn.cursor()
            
            # Get table list
            cursor.execute("""
                SELECT name FROM sqlite_master 
                WHERE type='table' AND name NOT LIKE 'sqlite_%'
                ORDER BY name
            """)
            tables = [row[0] for row in cursor.fetchall()]
            
            # Check for schema_migrations table
            if 'schema_migrations' in tables:
                cursor.execute("SELECT COALESCE(MAX(version), 0) FROM schema_migrations")
                version = cursor.fetchone()[0]
            else:
                # Legacy backup - infer version from table structure
                version = self.infer_schema_version_from_structure(conn, tables)
            
            schema_hash = self.calculate_schema_hash(backup_path)
            current_version = self.get_current_schema_version()
            
            # Determine compatibility
            if version == current_version:
                compatibility = 'compatible'
            elif version >= current_version - 3:  # Support 3 versions back
                compatibility = 'migration_required'
            else:
                compatibility = 'incompatible'
            
            return BackupInfo(
                version=version,
                schema_hash=schema_hash,
                tables=tables,
                compatibility_level=compatibility
            )
    
    def infer_schema_version_from_structure(self, conn: sqlite3.Connection, tables: List[str]) -> int:
        """Infer schema version from table structure for legacy backups"""
        cursor = conn.cursor()
        
        # Version detection based on table presence and structure
        version = 0
        
        # Base tables (version 1)
        if 'accounts' in tables and 'things' in tables:
            version = 1
            
        # Added strategists table (version 2)
        if 'strategists' in tables:
            version = 2
            
        # Added feed table (version 3)
        if 'feed' in tables:
            version = 3
            
        # Check for specific column additions
        if 'things' in tables:
            cursor.execute("PRAGMA table_info(things)")
            columns = [row[1] for row in cursor.fetchall()]
            
            # evidence_type_name column added in version 4
            if 'evidence_type_name' in columns:
                version = max(version, 4)
        
        logger.info(f"Inferred schema version {version} from table structure")
        return version
    
    def create_migration_plan(self, from_version: int, to_version: int) -> List[MigrationStep]:
        """Create migration plan from one version to another"""
        if from_version >= to_version:
            return []
            
        migration_steps = []
        
        # Define migrations for each version
        migrations = {
            1: [
                MigrationStep(
                    sql="CREATE TABLE IF NOT EXISTS schema_migrations (version INTEGER PRIMARY KEY, description TEXT, applied_at TEXT DEFAULT CURRENT_TIMESTAMP, sql_hash TEXT, swift_hash TEXT, rollback_sql TEXT, compatibility_version INTEGER)",
                    description="Add schema_migrations tracking table"
                )
            ],
            2: [
                MigrationStep(
                    sql="ALTER TABLE things ADD COLUMN evidence_type_name TEXT NULL DEFAULT NULL",
                    description="Add evidence_type_name to things table",
                    rollback_sql="-- Cannot rollback column addition safely"
                )
            ],
            3: [
                MigrationStep(
                    sql="""CREATE TABLE IF NOT EXISTS feed (
                        id INTEGER PRIMARY KEY,
                        account_id TEXT NOT NULL,
                        content_table TEXT NOT NULL,
                        content_id TEXT NOT NULL,
                        content_title TEXT,
                        priority INTEGER DEFAULT 0,
                        view_count INTEGER DEFAULT 0,
                        is_read BOOLEAN DEFAULT FALSE
                    )""",
                    description="Add feed table for user activity stream"
                )
            ],
            4: [
                MigrationStep(
                    sql="CREATE INDEX IF NOT EXISTS idx_feed_content ON feed(content_table, content_id)",
                    description="Add index for feed content lookups"
                )
            ]
        }
        
        # Collect all migration steps needed
        for version in range(from_version + 1, to_version + 1):
            if version in migrations:
                migration_steps.extend(migrations[version])
        
        return migration_steps
    
    def apply_migration_steps(self, db_path: Path, steps: List[MigrationStep]) -> bool:
        """Apply migration steps to database"""
        if not steps:
            return True
            
        try:
            with sqlite3.connect(db_path) as conn:
                cursor = conn.cursor()
                
                for step in steps:
                    logger.info(f"Applying migration: {step.description}")
                    
                    # Execute the migration SQL
                    if step.sql.strip():
                        cursor.execute(step.sql)
                    
                    # Record the migration
                    cursor.execute("""
                        INSERT INTO schema_migrations 
                        (version, description, applied_at, compatibility_version) 
                        VALUES (?, ?, ?, ?)
                    """, (
                        self.get_current_schema_version() + 1,
                        step.description,
                        datetime.now().isoformat(),
                        max(0, self.get_current_schema_version() - 2)  # Support 2 versions back
                    ))
                
                conn.commit()
                logger.info(f"Successfully applied {len(steps)} migration steps")
                return True
                
        except Exception as e:
            logger.error(f"Migration failed: {e}")
            return False
    
    def migrate_backup_to_current(self, backup_path: Path, target_path: Path) -> bool:
        """Migrate backup database to current schema version"""
        backup_info = self.detect_backup_schema_version(backup_path)
        current_version = self.get_current_schema_version()
        
        if backup_info.compatibility_level == 'incompatible':
            logger.error(f"Backup version {backup_info.version} is too old to migrate")
            return False
        
        if backup_info.version == current_version:
            # No migration needed, just copy
            shutil.copy2(backup_path, target_path)
            logger.info("Backup is already at current version, copied directly")
            return True
        
        # Create temporary copy for migration
        temp_path = target_path.with_suffix('.migrating')
        shutil.copy2(backup_path, temp_path)
        
        try:
            # Apply progressive migrations
            migration_steps = self.create_migration_plan(backup_info.version, current_version)
            
            if not migration_steps:
                logger.info("No migrations needed")
                shutil.move(temp_path, target_path)
                return True
            
            success = self.apply_migration_steps(temp_path, migration_steps)
            
            if success:
                shutil.move(temp_path, target_path)
                logger.info(f"Successfully migrated backup from version {backup_info.version} to {current_version}")
                return True
            else:
                temp_path.unlink(missing_ok=True)
                return False
                
        except Exception as e:
            logger.error(f"Migration failed: {e}")
            temp_path.unlink(missing_ok=True)
            return False
    
    def can_restore_backup(self, backup_path: Path) -> Tuple[bool, str]:
        """Check if backup can be restored"""
        try:
            backup_info = self.detect_backup_schema_version(backup_path)
            
            if backup_info.compatibility_level == 'compatible':
                return True, "Backup is compatible with current version"
            elif backup_info.compatibility_level == 'migration_required':
                return True, f"Backup can be migrated from version {backup_info.version}"
            else:
                return False, f"Backup version {backup_info.version} is too old to restore"
                
        except Exception as e:
            return False, f"Error analyzing backup: {e}"
    
    def create_backup_with_metadata(self, source_path: Path, backup_path: Path) -> bool:
        """Create backup with metadata for future restoration"""
        try:
            # Copy database
            shutil.copy2(source_path, backup_path)
            
            # Create metadata file
            metadata = {
                'version': self.get_current_schema_version(),
                'schema_hash': self.calculate_schema_hash(source_path),
                'created_at': datetime.now().isoformat(),
                'app_version': '1.0.0',  # Could be read from app bundle
                'compatibility_info': {
                    'min_supported_version': max(0, self.get_current_schema_version() - 3),
                    'migration_required': False
                }
            }
            
            metadata_path = backup_path.with_suffix('.metadata.json')
            with open(metadata_path, 'w') as f:
                json.dump(metadata, f, indent=2)
            
            logger.info(f"Created backup with metadata: {backup_path}")
            return True
            
        except Exception as e:
            logger.error(f"Backup creation failed: {e}")
            return False
    
    def get_migration_history(self) -> List[MigrationInfo]:
        """Get complete migration history"""
        if not self.db_path.exists():
            return []
            
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            
            # Check if schema_migrations table exists
            cursor.execute("""
                SELECT name FROM sqlite_master 
                WHERE type='table' AND name='schema_migrations'
            """)
            
            if not cursor.fetchone():
                return []
            
            cursor.execute("""
                SELECT version, description, applied_at, 
                       COALESCE(sql_hash, ''), COALESCE(swift_hash, ''),
                       COALESCE(rollback_sql, ''), COALESCE(compatibility_version, 0)
                FROM schema_migrations 
                ORDER BY version
            """)
            
            migrations = []
            for row in cursor.fetchall():
                migrations.append(MigrationInfo(
                    version=row[0],
                    description=row[1],
                    applied_at=row[2],
                    sql_hash=row[3],
                    swift_hash=row[4],
                    rollback_sql=row[5],
                    compatibility_version=row[6]
                ))
            
            return migrations


def main():
    """CLI interface for migration manager"""
    import argparse
    
    parser = argparse.ArgumentParser(description="RecordThing Migration Manager")
    parser.add_argument("--db", type=Path, required=True, help="Database file path")
    parser.add_argument("--backup", type=Path, help="Backup file to restore")
    parser.add_argument("--check", action="store_true", help="Check backup compatibility")
    parser.add_argument("--migrate", action="store_true", help="Migrate backup to current version")
    parser.add_argument("--history", action="store_true", help="Show migration history")
    
    args = parser.parse_args()
    
    manager = MigrationManager(args.db)
    
    if args.history:
        migrations = manager.get_migration_history()
        print(f"Migration History ({len(migrations)} migrations):")
        for migration in migrations:
            print(f"  v{migration.version}: {migration.description} ({migration.applied_at})")
    
    elif args.check and args.backup:
        can_restore, message = manager.can_restore_backup(args.backup)
        print(f"Backup compatibility: {'✅' if can_restore else '❌'} {message}")
        
        if can_restore:
            backup_info = manager.detect_backup_schema_version(args.backup)
            print(f"Backup info: {asdict(backup_info)}")
    
    elif args.migrate and args.backup:
        print(f"Migrating backup {args.backup} to {args.db}...")
        success = manager.migrate_backup_to_current(args.backup, args.db)
        print(f"Migration {'✅ succeeded' if success else '❌ failed'}")
    
    else:
        current_version = manager.get_current_schema_version()
        print(f"Current schema version: {current_version}")


if __name__ == "__main__":
    main()
