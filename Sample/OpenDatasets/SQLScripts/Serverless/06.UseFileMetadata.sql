/* Filename */
/* The following sample reads the NYC Yellow Taxi data files for the month September of 2017 and returns the number of rides per file. */
SELECT
    nyc.filename() AS [filename]
    ,COUNT_BIG(*) AS [rows]
FROM
    OPENROWSET(
    BULK 'https://sqlondemandstorage.blob.core.windows.net/public-parquet/taxi/year=2017/month=9/*.parquet',
    FORMAT='PARQUET'
    ) nyc
GROUP BY nyc.filename();

/* The following example shows how filename() can be used in the WHERE clause to filter the files to be read. */
SELECT
    r.filename() AS [filename]
    ,COUNT_BIG(*) AS [rows]
FROM OPENROWSET(
    BULK 'https://sqlondemandstorage.blob.core.windows.net/public-csv/taxi/yellow_tripdata_2017-*.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    FIRSTROW = 2)
    WITH (C1 varchar(200) ) AS [r]
WHERE
    r.filename() IN ('yellow_tripdata_2017-10.csv', 'yellow_tripdata_2017-11.csv', 'yellow_tripdata_2017-12.csv')
GROUP BY
    r.filename()
ORDER BY
    [filename];


/* Filepath */
/* The following sample reads NYC Yellow Taxi data files for the last three months of 2017. It returns the number of rides per file path. */
SELECT
    r.filepath() AS filepath
    ,COUNT_BIG(*) AS [rows]
FROM OPENROWSET(
    BULK 'https://sqlondemandstorage.blob.core.windows.net/public-csv/taxi/yellow_tripdata_2017-1*.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    FIRSTROW = 2
    )
    WITH (
        vendor_id INT
    ) AS [r]
GROUP BY
    r.filepath()
ORDER BY
    filepath;

/* The following example shows how filepath() can be used in the WHERE clause to filter the files to be read, shows the last three months of 2017. */
SELECT
    r.filepath() AS filepath
    ,r.filepath(1) AS [year]
    ,r.filepath(2) AS [month]
    ,COUNT_BIG(*) AS [rows]
FROM OPENROWSET(
    BULK 'https://sqlondemandstorage.blob.core.windows.net/public-csv/taxi/yellow_tripdata_*-*.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    FIRSTROW = 2
    )
WITH (
    vendor_id INT
) AS [r]
WHERE
    r.filepath(1) IN ('2017')
    AND r.filepath(2) IN ('10', '11', '12')
GROUP BY
    r.filepath()
    ,r.filepath(1)
    ,r.filepath(2)
ORDER BY
    filepath;
