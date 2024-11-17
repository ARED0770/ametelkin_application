import sqlite3

def create_connection(db_file):
    conn = sqlite3.connect(db_file)
    return conn

def create_table(conn):
    create_table_sql = """
    CREATE TABLE IF NOT EXISTS klines (
        id INTEGER PRIMARY KEY,
        timestamp INTEGER NOT NULL,
        open REAL NOT NULL,
        high REAL NOT NULL,
        low REAL NOT NULL,
        close REAL NOT NULL,
        volume REAL NOT NULL
    );
    """
    conn.execute(create_table_sql)
    conn.commit()

def insert_kline(conn, kline):
    sql = ''' INSERT INTO klines(timestamp, open, high, low, close, volume)
              VALUES(?,?,?,?,?,?) '''
    cur = conn.cursor()
    cur.execute(sql, kline)
    conn.commit()
