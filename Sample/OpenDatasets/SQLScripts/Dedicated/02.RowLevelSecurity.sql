--Create three user accounts that will demonstrate different access capabilities
CREATE USER Manager WITHOUT LOGIN;
CREATE USER Sales1 WITHOUT LOGIN;
CREATE USER Sales2 WITHOUT LOGIN;

--Create a table to hold data
CREATE TABLE Sales
    (
    OrderID int,
    SalesRep sysname,
    Product varchar(10),
    Qty int
    );

--Insert data into table with six rows of data, showing three orders for each sales representative
INSERT INTO Sales VALUES (1, 'Sales1', 'Valve', 5);
INSERT INTO Sales VALUES (2, 'Sales1', 'Wheel', 2);
INSERT INTO Sales VALUES (3, 'Sales1', 'Valve', 4);
INSERT INTO Sales VALUES (4, 'Sales2', 'Bracket', 2);
INSERT INTO Sales VALUES (5, 'Sales2', 'Wheel', 5);
INSERT INTO Sales VALUES (6, 'Sales2', 'Seat', 5);
-- View the 6 rows in the table
SELECT * FROM Sales;

--Grant read access on the table to each of the users
GRANT SELECT ON Sales TO Manager;
GRANT SELECT ON Sales TO Sales1;
GRANT SELECT ON Sales TO Sales2;


--Create a new schema, and an inline table-valued function.
--The function returns 1 when a row in the SalesRep column is the same as the user executing the query (@SalesRep = USER_NAME()) or if the user executing the query is the Manager user (USER_NAME() = 'Manager')
EXEC('CREATE SCHEMA Security');
GO

  --Select the code for creating the function and run
CREATE FUNCTION Security.fn_securitypredicate(@SalesRep AS sysname)
    RETURNS TABLE
WITH SCHEMABINDING
AS
    RETURN SELECT 1 AS fn_securitypredicate_result
WHERE @SalesRep = USER_NAME() OR USER_NAME() = 'Manager'
GO
--Create a security policy adding the function as a filter predicate. The state must be set to ON to enable the policy.
CREATE SECURITY POLICY SalesFilter
ADD FILTER PREDICATE Security.fn_securitypredicate(SalesRep)
ON dbo.Sales
WITH (STATE = ON);

--Allow SELECT permissions to the fn_securitypredicate function
GRANT SELECT ON security.fn_securitypredicate TO Manager;
GRANT SELECT ON security.fn_securitypredicate TO Sales1;
GRANT SELECT ON security.fn_securitypredicate TO Sales2;

--Test the filtering predicate, by selected from the Sales table as each user
EXECUTE AS USER = 'Sales1';
SELECT * FROM Sales;
REVERT;

EXECUTE AS USER = 'Sales2';
SELECT * FROM Sales;
REVERT;

EXECUTE AS USER = 'Manager';
SELECT * FROM Sales;
REVERT;

--Alter the security policy to disable the policy
ALTER SECURITY POLICY SalesFilter
WITH (STATE = OFF);

--Connect to the SQL database to clean up resources
DROP USER Sales1;
DROP USER Sales2;
DROP USER Manager;

DROP SECURITY POLICY SalesFilter;
DROP TABLE Sales;
DROP FUNCTION Security.fn_securitypredicate;
DROP SCHEMA Security;
