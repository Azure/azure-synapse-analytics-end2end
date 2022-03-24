/* The example extracts scalar and objects values from COVID-19 Open Research Dataset JSON file with nested objects is shown below.*/
SELECT
    title = JSON_VALUE(doc, '$.metadata.title'),
    first_author = JSON_QUERY(doc, '$.metadata.authors[0]'),
    first_author_name = JSON_VALUE(doc, '$.metadata.authors[0].first'),
    complex_object = doc
FROM
    OPENROWSET(
        BULK 'https://azureopendatastorage.blob.core.windows.net/covid19temp/comm_use_subset/pdf_json/000b7d1517ceebb34e1e3e817695b6de03e2fa78.json',
        FORMAT='CSV', FIELDTERMINATOR ='0x0b', FIELDQUOTE = '0x0b', ROWTERMINATOR = '0x0b'
    )
    WITH ( doc varchar(MAX) ) AS docs;


/* Project nested or repeated data */
SELECT
    DateStruct, TimeStruct, TimestampStruct, DecimalStruct, FloatStruct
FROM
    OPENROWSET(
        BULK 'https://sqlondemandstorage.blob.core.windows.net/public-parquet/nested/structExample.parquet',
        FORMAT='PARQUET'
    )
    WITH (
        DateStruct VARCHAR(8000),
        TimeStruct VARCHAR(8000),
        TimestampStruct VARCHAR(8000),
        DecimalStruct VARCHAR(8000),
        FloatStruct VARCHAR(8000)
    ) AS [r];

/* The following query reads the justSimpleArray.parquet file. */
SELECT
    SimpleArray
FROM
    OPENROWSET(
        BULK 'https://sqlondemandstorage.blob.core.windows.net/public-parquet/nested/justSimpleArray.parquet',
        FORMAT='PARQUET'
    ) AS [r];


/* Read properties from nested object columns */
SELECT
    title = JSON_VALUE(complex_column, '$.metadata.title'),
    first_author_name = JSON_VALUE(complex_column, '$.metadata.authors[0].first'),
    body_text = JSON_VALUE(complex_column, '$.body_text.text'),
    complex_column
FROM
    OPENROWSET( BULK 'https://azureopendatastorage.blob.core.windows.net/covid19temp/comm_use_subset/pdf_json/000b7d1517ceebb34e1e3e817695b6de03e2fa78.json',
                FORMAT='CSV', FIELDTERMINATOR ='0x0b', FIELDQUOTE = '0x0b', ROWTERMINATOR = '0x0b' ) WITH ( complex_column varchar(MAX) ) AS docs;

/* The following query reads the structExample.parquet file and shows how to surface elements of a nested column. */
SELECT
    *
FROM
    OPENROWSET(
        BULK 'https://sqlondemandstorage.blob.core.windows.net/public-parquet/nested/structExample.parquet',
        FORMAT='PARQUET'
    )
    WITH (
        [DateValue] DATE '$.DateStruct.Date',
        [TimeStruct.Time] TIME,
        [TimestampStruct.Timestamp] DATETIME2,
        DecimalValue DECIMAL(18, 5) '$.DecimalStruct.Decimal',
        [FloatStruct.Float] FLOAT
    ) AS [r];


/* Access elements from repeated columns */
SELECT
    *,
    JSON_VALUE(SimpleArray, '$[0]') AS FirstElement,
    JSON_VALUE(SimpleArray, '$[1]') AS SecondElement,
    JSON_VALUE(SimpleArray, '$[2]') AS ThirdElement
FROM
    OPENROWSET(
        BULK 'https://sqlondemandstorage.blob.core.windows.net/public-parquet/nested/justSimpleArray.parquet',
        FORMAT='PARQUET'
    ) AS [r];


/* Access sub-objects from complex columns */
SELECT
    MapOfPersons,
    JSON_QUERY(MapOfPersons, '$."John Doe"') AS [John]
FROM
    OPENROWSET(
        BULK 'https://sqlondemandstorage.blob.core.windows.net/public-parquet/nested/mapExample.parquet',
        FORMAT='PARQUET'
    ) AS [r];

/* Explicitly reference the columns that you want to return in WITH clause */
SELECT DocId,
    MapOfPersons,
    JSON_QUERY(MapOfPersons, '$."John Doe"') AS [John]
FROM
    OPENROWSET(
        BULK 'https://sqlondemandstorage.blob.core.windows.net/public-parquet/nested/mapExample.parquet',
        FORMAT='PARQUET'
    )
    WITH (DocId bigint, MapOfPersons VARCHAR(max)) AS [r];


/* Project values from repeated columns */
SELECT
    SimpleArray, Element
FROM
    OPENROWSET(
        BULK 'https://sqlondemandstorage.blob.core.windows.net/public-parquet/nested/justSimpleArray.parquet',
        FORMAT='PARQUET'
    ) AS arrays
    CROSS APPLY OPENJSON (SimpleArray) WITH (Element int '$') as array_values
