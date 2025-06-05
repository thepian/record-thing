#!/usr/bin/env python
"""
CLI utilities for Record Thing.
"""
import argparse
import json
import logging
import os
import sqlite3
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

from .bunny.config import BunnyConfig
from .bunny.sync import BunnySync
from .commons import DBP, FREE_TEAM_ID, PREMIUM_TEAM_ID
from .db.connection import (
    connect_to_db,
    get_db_tables,
    show_database_info,
    test_connection,
)
from .db.schema import ensure_empty_db
from .db_setup import create_database, create_tables, insert_sample_data, update_schema

# Import token manager with conditional import to handle missing keyring
try:
    from .security import TokenManager

    TOKEN_MANAGER_AVAILABLE = True
except ImportError:
    TOKEN_MANAGER_AVAILABLE = False

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def init_db_command(args) -> None:
    """Initialize the database."""
    db_path = args.db_path or DBP

    # Check if the database exists
    exists = db_path.exists()

    if exists and not args.force:
        logger.info(f"Database already exists at {db_path}")
        logger.info("Use --force to reset the database.")
        show_database_info(db_path)
        return

    # Create or reset the database
    logger.info(f"{'Creating' if not exists else 'Resetting'} database at {db_path}")
    # Ensure directory exists
    db_path.parent.mkdir(parents=True, exist_ok=True)
    # First make sure file can be created
    ensure_empty_db(db_path)
    # Then create the database
    create_database(db_path)

    logger.info("Database initialization complete.")
    show_database_info(db_path)


def update_db_command(args) -> None:
    """Update the database schema without losing data."""
    db_path = args.db_path or DBP

    # Check if the database exists
    if not db_path.exists():
        logger.error(f"Database not found at {db_path}")
        logger.info("Run 'init-db' to create a new database.")
        return

    logger.info(f"Updating database schema at {db_path}")

    try:
        # Use the update_schema function from db_setup.py
        update_schema(db_path)

        # Show the updated database info
        show_database_info(db_path)
    except Exception as e:
        logger.error(f"Failed to update database: {e}")
        sys.exit(1)


def tables_db_command(args) -> None:
    """Create tables in the database without sample data."""
    db_path = args.db_path or DBP

    logger.info(f"Creating tables in database at {db_path}")

    try:
        # Use the create_tables function from db_setup.py
        create_tables(db_path)

        # Show the database info
        show_database_info(db_path)
    except Exception as e:
        logger.error(f"Failed to create tables: {e}")
        sys.exit(1)


def populate_db_command(args) -> None:
    """Insert sample data into the database."""
    db_path = args.db_path or DBP

    # Check if the database exists
    if not db_path.exists():
        logger.error(f"Database not found at {db_path}")
        logger.info("Run 'init-db' to create a new database.")
        return

    logger.info(f"Inserting sample data into database at {db_path}")

    try:
        # Use the insert_sample_data function from db_setup.py
        insert_sample_data(db_path)

        # Show the database info
        show_database_info(db_path)
    except Exception as e:
        logger.error(f"Failed to insert sample data: {e}")
        sys.exit(1)


def test_db_command(args) -> None:
    """Test database connection and display information."""
    db_path = args.db_path or DBP

    # Test the connection
    result = test_connection(db_path)
    if result:
        logger.info(f"✅ Successfully connected to database at {db_path}")

        # If verbose, show more information
        if args.verbose:
            conn = connect_to_db(db_path, read_only=True)
            try:
                tables = get_db_tables(conn)
                logger.info(f"Found {len(tables)} tables: {', '.join(tables)}")
            finally:
                conn.close()
    else:
        logger.error(f"❌ Failed to connect to database at {db_path}")
        sys.exit(1)


def get_team_config(team_id: str, db_path: Path) -> Dict[str, Any]:
    """
    Get team configuration from the database.

    Args:
        team_id: The team ID to look up
        db_path: Path to the database

    Returns:
        Dict containing team configuration

    Raises:
        ValueError: If team is not found
    """
    if not db_path.exists():
        raise ValueError(f"Database not found: {db_path}")

    conn = None
    try:
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        cursor.execute(
            """
            SELECT 
                team_id, name, region, tier, 
                storage_domain, storage_bucket_name, storage_bucket_region,
                fallback_domain, fallback_bucket_name, fallback_bucket_region
            FROM teams
            WHERE team_id = ?
            """,
            (team_id,),
        )

        team = cursor.fetchone()
        if not team:
            raise ValueError(f"Team not found with ID: {team_id}")

        # Convert to dictionary
        return {
            "team_id": team["team_id"],
            "name": team["name"],
            "region": team["region"],
            "tier": team["tier"],
            "storage_domain": team["storage_domain"],
            "storage_bucket_name": team["storage_bucket_name"],
            "storage_bucket_region": team["storage_bucket_region"],
            "fallback_domain": team["fallback_domain"],
            "fallback_bucket_name": team["fallback_bucket_name"],
            "fallback_bucket_region": team["fallback_bucket_region"],
        }

    except Exception as e:
        raise ValueError(f"Error getting team config: {e}")

    finally:
        if conn:
            conn.close()


def validate_user_id(user_id: str) -> bool:
    """
    Validate that a user ID is in the correct format (basic check).

    Args:
        user_id: User ID to validate

    Returns:
        True if valid, False otherwise
    """
    # Add validation logic here - for now just checking it's not empty
    return isinstance(user_id, str) and len(user_id) > 0


def token_command(args) -> None:
    """Manage API tokens securely."""
    if not TOKEN_MANAGER_AVAILABLE:
        logger.error(
            "Token management is not available. Please install the required dependencies:"
        )
        logger.error("  uv pip install keyring")
        sys.exit(1)

    # If no subcommand is provided, show usage instructions
    if args.token_action is None:
        print("Record Thing Token Management")
        print("\nUsage:")
        print("  token set <service> [--token VALUE]  Save an API token")
        print(
            "  token get <service>                  Retrieve an API token (requires authentication)"
        )
        print("  token list                           List available tokens")
        print("  token delete <service>               Delete an API token")
        print("\nExamples:")
        print("  uv run -m record_thing.cli token set premium")
        print("  uv run -m record_thing.cli token get free")
        print("  uv run -m record_thing.cli token list")
        print("  uv run -m record_thing.cli token delete bunny")
        print("\nService Names:")
        print("  premium    - Premium tier storage bucket API key")
        print("  common     - Free tier storage bucket API key")
        print("  demo       - Internal demo storage bucket API key")
        print("  bunny      - BunnyCDN API key")
        print("  <custom>   - Any custom service name")
        print("\nIntegration with other commands:")
        print("  sync-user  - Uses tokens automatically when --api-key is omitted")
        return

    token_manager = TokenManager()

    if args.token_action == "set":
        # Save a token
        success = token_manager.save_token(args.service, args.token)
        if not success:
            logger.error(f"Failed to save token for {args.service}")
            sys.exit(1)

    elif args.token_action == "get":
        # Retrieve a token
        token = token_manager.get_token(args.service)
        if token:
            print(token)
        else:
            logger.error(f"No token found for {args.service} or authentication failed")
            sys.exit(1)

    elif args.token_action == "list":
        # List available tokens
        services = token_manager.list_services()
        if services:
            print("Available tokens:")
            for service in services:
                print(f"  - {service}")
        else:
            print("No tokens found")

    elif args.token_action == "delete":
        # Delete a token
        success = token_manager.delete_token(args.service)
        if not success:
            logger.error(f"Failed to delete token for {args.service}")
            sys.exit(1)

    else:
        logger.error("Unknown token action")
        sys.exit(1)


def sync_user_dir_command(args) -> None:
    """Download a user directory from a team storage bucket."""
    db_path = args.db_path or DBP

    # Validate inputs
    if not validate_user_id(args.user_id):
        logger.error(f"Invalid user ID: {args.user_id}")
        sys.exit(1)

    # If no team ID is provided, use the default based on tier
    team_id = args.team_id
    if not team_id:
        team_id = PREMIUM_TEAM_ID if args.premium else FREE_TEAM_ID

    logger.info(f"Looking up team configuration for team: {team_id}")

    # Get API key from token storage if not provided directly
    api_key = args.api_key
    if not api_key and TOKEN_MANAGER_AVAILABLE:
        # Determine which service name to use for the API key
        service_name = args.token_service
        if not service_name:
            # Default to team-based naming if not specified
            service_name = "premium" if team_id == PREMIUM_TEAM_ID else "free"
            if team_id != PREMIUM_TEAM_ID and team_id != FREE_TEAM_ID:
                service_name = f"team_{team_id}"

        logger.info(
            f"Retrieving API key from secure storage for service: {service_name}"
        )
        token_manager = TokenManager()
        api_key = token_manager.get_token(service_name)

        if not api_key:
            logger.error(
                f"No API key found for {service_name}. Please provide --api-key or "
                f"save a token with 'token set {service_name}'"
            )
            sys.exit(1)
    elif not api_key:
        logger.error("No API key provided. Please specify with --api-key")
        sys.exit(1)

    try:
        # Get team configuration from database
        team_config = get_team_config(team_id, db_path)

        # Create local directory if it doesn't exist
        output_dir = args.output_dir
        if not output_dir:
            output_dir = Path(os.getcwd()) / "users" / args.user_id

        output_dir.mkdir(parents=True, exist_ok=True)

        logger.info(f"Using storage bucket: {team_config['storage_bucket_name']}")
        logger.info(f"Output directory: {output_dir}")

        # Create BunnyConfig from team configuration
        config = BunnyConfig(
            storage_zone_name=team_config["storage_bucket_name"],
            api_key=api_key,
            hostname=team_config["storage_domain"],
            storage_region=team_config["storage_bucket_region"],
        )

        # Initialize BunnySync
        bunny_sync = BunnySync(config)

        # Test the connection
        connection_test = bunny_sync.test_connection()
        if not connection_test["api_key"]:
            logger.error("Failed to connect to storage bucket. Check your API key.")
            sys.exit(1)

        # Construct the user directory path
        user_dir = args.user_id

        # Define sync paths - which subdirectories to sync
        sync_paths = [user_dir]
        if args.sync_paths:
            # If specific subdirectories are provided, use those
            sync_paths = [f"{user_dir}/{path}" for path in args.sync_paths]

        # Perform the sync
        logger.info(f"Starting sync of user directory: {user_dir}")
        result = bunny_sync.sync(
            local_path=output_dir,
            max_workers=args.workers,
            delete_orphaned=args.delete_orphaned,
            sync_paths=sync_paths,
        )

        # Report results
        logger.info(
            f"Sync complete: {result['downloaded']} files downloaded, {result['deleted']} files deleted"
        )
        if result["errors"]:
            logger.warning(f"Encountered {len(result['errors'])} errors during sync")
            if args.verbose:
                for error in result["errors"]:
                    logger.warning(f"Error: {error}")

        logger.info(f"User directory synced successfully to: {output_dir}")

    except ValueError as e:
        logger.error(str(e))
        sys.exit(1)
    except Exception as e:
        logger.error(f"Error syncing user directory: {e}")
        import traceback

        logger.debug(traceback.format_exc())
        sys.exit(1)


def main() -> None:
    """Main entry point for the CLI."""
    parser = argparse.ArgumentParser(description="Record Thing CLI")
    subparsers = parser.add_subparsers(dest="command", help="Command to run")

    # init-db command
    init_db_parser = subparsers.add_parser("init-db", help="Initialize the database")
    init_db_parser.add_argument(
        "--db-path", type=Path, help=f"Path to the database (default: {DBP})"
    )
    init_db_parser.add_argument(
        "--force",
        action="store_true",
        help="Force reset of the database if it already exists",
    )
    init_db_parser.set_defaults(func=init_db_command)

    # update-db command
    update_db_parser = subparsers.add_parser(
        "update-db", help="Update database schema without data loss"
    )
    update_db_parser.add_argument(
        "--db-path", type=Path, help=f"Path to the database (default: {DBP})"
    )
    update_db_parser.set_defaults(func=update_db_command)

    # tables-db command
    tables_db_parser = subparsers.add_parser(
        "tables-db", help="Create tables without sample data"
    )
    tables_db_parser.add_argument(
        "--db-path", type=Path, help=f"Path to the database (default: {DBP})"
    )
    tables_db_parser.set_defaults(func=tables_db_command)

    # populate-db command
    populate_db_parser = subparsers.add_parser(
        "populate-db", help="Insert sample data into the database"
    )
    populate_db_parser.add_argument(
        "--db-path", type=Path, help=f"Path to the database (default: {DBP})"
    )
    populate_db_parser.set_defaults(func=populate_db_command)

    # test-db command
    test_db_parser = subparsers.add_parser("test-db", help="Test database connection")
    test_db_parser.add_argument(
        "--db-path", type=Path, help=f"Path to the database (default: {DBP})"
    )
    test_db_parser.add_argument(
        "-v", "--verbose", action="store_true", help="Show detailed information"
    )
    test_db_parser.set_defaults(func=test_db_command)

    # token command
    token_parser = subparsers.add_parser("token", help="Manage API tokens securely")
    token_subparsers = token_parser.add_subparsers(dest="token_action")

    # Set token
    set_parser = token_subparsers.add_parser("set", help="Save an API token")
    set_parser.add_argument(
        "service", help="Service name (e.g., 'bunny', 'premium', 'free')"
    )
    set_parser.add_argument("--token", help="Token value (omit to enter securely)")

    # Get token
    get_parser = token_subparsers.add_parser("get", help="Retrieve an API token")
    get_parser.add_argument("service", help="Service name to retrieve")

    # List tokens
    list_parser = token_subparsers.add_parser("list", help="List available tokens")

    # Delete token
    delete_parser = token_subparsers.add_parser("delete", help="Delete an API token")
    delete_parser.add_argument("service", help="Service name to delete")

    token_parser.set_defaults(func=token_command)

    # sync-user command
    sync_user_parser = subparsers.add_parser(
        "sync-user", help="Download a user directory from a team storage bucket"
    )
    sync_user_parser.add_argument("user_id", type=str, help="User ID to download")
    sync_user_parser.add_argument(
        "--team-id",
        type=str,
        help=f"Team ID (default: {PREMIUM_TEAM_ID} if --premium, {FREE_TEAM_ID} otherwise)",
    )
    sync_user_parser.add_argument(
        "--premium",
        action="store_true",
        help=f"Use premium team ID ({PREMIUM_TEAM_ID}) if no team ID is provided",
    )
    sync_user_parser.add_argument(
        "--api-key",
        type=str,
        help="API key for storage bucket access (if not provided, will attempt to retrieve from token storage)",
    )
    sync_user_parser.add_argument(
        "--token-service",
        type=str,
        help="Service name to use for token retrieval (defaults to 'premium' or 'free' based on team)",
    )
    sync_user_parser.add_argument(
        "--output-dir", type=Path, help="Output directory (default: ./users/<user_id>)"
    )
    sync_user_parser.add_argument(
        "--sync-paths",
        nargs="+",
        type=str,
        help="Specific subdirectories to sync (e.g., 'database assets')",
    )
    sync_user_parser.add_argument(
        "--workers",
        type=int,
        default=4,
        help="Number of parallel workers for sync operations (default: 4)",
    )
    sync_user_parser.add_argument(
        "--delete-orphaned",
        action="store_true",
        help="Delete local files that don't exist in the remote bucket",
    )
    sync_user_parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Show detailed information and errors",
    )
    sync_user_parser.add_argument(
        "--db-path", type=Path, help=f"Path to the database (default: {DBP})"
    )
    sync_user_parser.set_defaults(func=sync_user_dir_command)

    # Parse arguments
    args = parser.parse_args()

    if args.command is None:
        parser.print_help()
        sys.exit(1)

    # Execute the command
    args.func(args)


if __name__ == "__main__":
    main()
