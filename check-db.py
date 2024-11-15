

# file:///Users/henrikvendelbo/Library/Developer/CoreSimulator/Devices/AE314069-888C-4933-877D-672FCB9A18FC/data/Containers/Data/Application/5649A52E-106C-4D3F-AF2D-2790F7752B06/Documents/record-thing.sqlite

import sqlite3

ROOT_NAMES = ['Electronics', 'Pet', 'Room', 'Furniture', 'Jewelry', 'Sports', 'Transportation', 'Clothing']

db_path = '/Users/henrikvendelbo/Library/Developer/CoreSimulator/Devices/AE314069-888C-4933-877D-672FCB9A18FC/data/Containers/Data/Application/5649A52E-106C-4D3F-AF2D-2790F7752B06/Documents/record-thing.sqlite'
try:
    with sqlite3.connect(db_path) as conn:
        cursor = conn.cursor()

        # Check if root types are inserted
        count_types = cursor.execute('SELECT COUNT(*) as count_types FROM ProductType')
        counted = count_types.fetchall()[0]
        if counted[0] == 0:
            print('Inserting root types')
            cursor.executemany('INSERT INTO ProductType VALUES (?, ?, ?)', [(n, '-', None) for n in ROOT_NAMES])
            conn.commit()
        else:
            print('Root types already inserted', counted)
except sqlite3.OperationalError as e:
    print(e)
