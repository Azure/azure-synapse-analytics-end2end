/* This is a sample script for loading and scoring machine learning models using New York taxi data.
   The query scenario is to predict the fare for taking a trip around New York City.
   First, create two tables: to store the sample machine learning model and scoring data.
   Next, load the data and the model in their respective tables.
   Last, use T-SQL Predict to score the model.
   Run the script below to see the results.
*/

-- Create a table to store the model.
CREATE TABLE [dbo].[AllModels]
(
    [Model] [varbinary](max) NULL
)
WITH
(
    DISTRIBUTION = ROUND_ROBIN,
    HEAP
)
GO

-- Next, load the hexadecimal string of the model from Azure Data Lake storage location into the table.
COPY INTO [AllModels] (Model)
FROM 'https://nytaxiblob.blob.core.windows.net/samplepredictdata/NYC-fare-prediction.onnx.hex'
WITH (
    FILE_TYPE = 'CSV'
)

-- Create a table to store the sample scoring data.
CREATE TABLE [dbo].[TaxiTrips]
(
	[vendorID] [real] NOT NULL,
	[passengerCount] [real] NULL,
	[tripDistance] [real] NULL,
	[month_num] [real] NULL,
	[day_of_month] [real] NULL,
	[day_of_week] [real] NULL,
	[day_of_hour] [real] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

-- Next, load the sample data from the Azure Data Lake location.
COPY INTO [dbo].[TaxiTrips] (vendorID, passengerCount, tripDistance, month_num, day_of_month, day_of_week, day_of_hour)
FROM 'https://nytaxiblob.blob.core.windows.net/samplepredictdata/tripstestdata.csv'
WITH (
    FILE_TYPE = 'CSV',
	FIRSTROW = 2,
    FIELDTERMINATOR=',',
    ROWTERMINATOR='0x0A'
	)

-- Use Predict find out what the fare of various trips around New York City is.
-- A new column is generated called totalAmount with data type float that will contain the predicted amount.
SELECT [vendorID],
 	   [passengerCount],
	   [tripDistance],
	   [month_num],
	   [day_of_month],
	   [day_of_week],
	   [day_of_hour],
	   [totalAmount]
FROM PREDICT (model = (SELECT Model FROM AllModels), Data = dbo.TaxiTrips, RUNTIME=ONNX) WITH (totalAmount float)
