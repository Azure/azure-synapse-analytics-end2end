/* Covid-19 ECDC cases opendata set */

/* Read JSON files */
SELECT TOP 10 *
FROM OPENROWSET(
        BULK 'https://pandemicdatalake.blob.core.windows.net/public/curated/covid-19/ecdc_cases/latest/ecdc_cases.json',
        FORMAT = 'csv',
        FIELDTERMINATOR ='0x0b',
        FIELDQUOTE = '0x0b'
    ) with (doc nvarchar(max)) as rows
go
SELECT TOP 10 *
FROM OPENROWSET(
        BULK 'https://pandemicdatalake.blob.core.windows.net/public/curated/covid-19/ecdc_cases/latest/ecdc_cases.json',
        FORMAT = 'csv',
        FIELDTERMINATOR ='0x0b',
        FIELDQUOTE = '0x0b',
        ROWTERMINATOR = '0x0b' --> You need to override rowterminator to read classic JSON
    ) WITH (doc nvarchar(max)) as rows


/* Books dataset */

/* In order to process JSON files using JSON_VALUE and JSON_QUERY you need to to read json file from storage as single column.
Following script reads book1.json file as single column. */

SELECT
    *
FROM
    OPENROWSET(
        BULK 'https://sqlondemandstorage.blob.core.windows.net/public-json/books/book1.json',
        FORMAT='CSV',
        FIELDTERMINATOR ='0x0b',
        FIELDQUOTE = '0x0b',
        ROWTERMINATOR = '0x0b'
    )
    WITH (
        jsonContent varchar(8000)
    ) AS [r]

/* Querying JSON files using JSON_VALUE */

/*Following query shows how to use JSON_VALUE to retrieve scalar values (title, publisher)
from book with title Probabilistic and Statistical Methods in Cryptology, An Introduction by Selected Topics.*/
SELECT
    JSON_VALUE(jsonContent, '$.title') AS title,
	JSON_VALUE(jsonContent, '$.publisher') as publisher,
	jsonContent
FROM
    OPENROWSET(
        BULK 'https://sqlondemandstorage.blob.core.windows.net/public-json/books/*.json',
		FORMAT='CSV',
        FIELDTERMINATOR ='0x0b',
        FIELDQUOTE = '0x0b',
        ROWTERMINATOR = '0x0b'
    )
    WITH (
        jsonContent varchar(8000)
    ) AS [r]
WHERE
	JSON_VALUE(jsonContent, '$.title') = 'Probabilistic and Statistical Methods in Cryptology, An Introduction by Selected Topics'

/* Querying JSON files using JSON_QUERY */

/* Following query shows how to use JSON_QUERY to retrieve objects and arrays (authors)
from book with title Probabilistic and Statistical Methods in Cryptology, An Introduction by Selected Topics. */

SELECT
    JSON_QUERY(jsonContent, '$.authors') AS authors,
	jsonContent
FROM
    OPENROWSET(
        BULK 'https://sqlondemandstorage.blob.core.windows.net/public-json/books/*.json',
		FORMAT='CSV',
        FIELDTERMINATOR ='0x0b',
        FIELDQUOTE = '0x0b',
        ROWTERMINATOR = '0x0b'
    )
    WITH (
        jsonContent varchar(8000)
    ) AS [r]
WHERE
	JSON_VALUE(jsonContent, '$.title') = 'Probabilistic and Statistical Methods in Cryptology, An Introduction by Selected Topics'

/* Querying JSON files using OPENJSON */

/* Following query shows how to use OPENJSON to retrieve objects and properties
within book with title Probabilistic and Statistical Methods in Cryptology, An Introduction by Selected Topics. */

SELECT
	j.*
FROM
    OPENROWSET(
        BULK 'https://sqlondemandstorage.blob.core.windows.net/public-json/books/*.json',
		FORMAT='CSV',
        FIELDTERMINATOR ='0x0b',
        FIELDQUOTE = '0x0b',
        ROWTERMINATOR = '0x0b'
    )
    WITH (
        jsonContent NVARCHAR(4000) --Note that we have to use NVARCHAR(4000) for OPENJSON to work.
    ) AS [r]
CROSS APPLY OPENJSON(jsonContent) AS j
WHERE
	JSON_VALUE(jsonContent, '$.title') = 'Probabilistic and Statistical Methods in Cryptology, An Introduction by Selected Topics'
