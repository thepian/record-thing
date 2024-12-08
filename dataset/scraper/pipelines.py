# image_scraper/pipelines.py
import os
import sqlite3
import json
import aiosqlite
import asyncio

class SQLitePipeline:
    def __init__(self, db_path):
        self.db_path = db_path
    
    @classmethod
    def from_crawler(cls, crawler):
        return cls(
            db_path=crawler.settings.get('SQLITE_DB_PATH', './images.db')
        )
    
    async def _create_table(self):
        async with aiosqlite.connect(self.db_path) as db:
            await db.execute('''
                CREATE TABLE IF NOT EXISTS image_data (
                    url TEXT PRIMARY KEY,
                    sha1_hash TEXT,
                    file_path TEXT,
                    dino_embedding TEXT
                )
            ''')
            await db.commit()
    
    async def _insert_item(self, item):
        async with aiosqlite.connect(self.db_path) as db:
            await db.execute('''
                INSERT OR REPLACE INTO image_data 
                (url, sha1_hash, file_path, dino_embedding) 
                VALUES (?, ?, ?, ?)
            ''', (
                item['url'], 
                item['sha1_hash'], 
                item['file_path'], 
                json.dumps(item['dino_embedding'])
            ))
            await db.commit()
    
    def open_spider(self, spider):
        # Create table synchronously during spider startup
        asyncio.run(self._create_table())
    
    def process_item(self, item, spider):
        # Run async insert in event loop
        asyncio.run(self._insert_item(item))
        return item

