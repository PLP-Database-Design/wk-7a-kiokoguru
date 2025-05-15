Assuming a hypothetical SQL function split() (which needs to be implemented in real use as many standard SQL dialects may not offer this out of the box):

CREATE TABLE ProductDetails_1NF (
    OrderID INT,
    Product VARCHAR(255),
    CustomerName VARCHAR(100)
);

-- Hypothetical function usage
INSERT INTO ProductDetails_1NF (OrderID, Product, CustomerName)
SELECT OrderID, P, CustomerName
FROM (
    SELECT OrderID, 
           SUBSTRING_INDEX(Products, ',', 1) AS P,
           CustomerName
    FROM ProductDetail
    CROSS JOIN (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3) AS SplitRows
    WHERE Products LIKE CONCAT(SUBSTRING_INDEX(Products, ',', 1),',%')
) AS Subquery;

-- The above query assumes a maximum of 3 products per order and uses a manual split method.
-- The exact implementation depends on your SQL dialect and its capabilities.

-- This approach might need adjustment based on the actual SQL environment you use.
-- For instance, in PostgreSQL, you could use the `string_to_array()` function.
-- In MySQL, you may need to create a stored procedure or use a user-defined function.
-- In SQL Server, you can use CLR functions or a CROSS APPLY with XML PATH trick.

-- Here's how it might look in PostgreSQL, where splitting is more straightforward:
-- Assuming 'split_parts' is a function to split a string into array elements:
INSERT INTO ProductDetails_1NF (OrderID, Product, CustomerName)
SELECT OrderID, p, CustomerName
FROM ProductDetail, 
     LATERAL STRING_TO_ARRAY(Products, ',') AS split_parts
ORDER BY OrderID, split_parts;





Step 1: Create the 'Customers' table if it doesn't exist.

CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(100) UNIQUE
);

-- Assuming that you want to assign a unique CustomerID to each customer
-- You might need to perform this insertion manually or through a script
-- Here, I'll provide a conceptual way to insert into the Customers table
INSERT INTO Customers (CustomerName, CustomerID)
SELECT DISTINCT CustomerName,
       (SELECT COUNT(*) FROM OrderDetails WHERE CustomerName = od.CustomerName) AS CustomerID -- This is a placeholder, actual implementation might differ
FROM OrderDetails od;

-- Note: The above SELECT for CustomerID is conceptual and may require a different approach
--      depending on how you intend to manage CustomerID (auto-increment or manually assigned).

-- In a real implementation, the CustomerID would typically be auto-incremented in the Customers table
-- or assigned based on existing business logic or a unique identifier for the customers.

**Step 2: Update the OrderDetails table to include only the CustomerID (Foreign Key) and remove CustomerName**

This step involves deleting the CustomerName column from the OrderDetails table and adding a foreign key reference to the Customers table. However, since the above step merely illustrates the creation of the Customers table, let's focus on the SQL needed to adjust OrderDetails:

**Adjust OrderDetails:**

```sql
ALTER TABLE OrderDetails DROP COLUMN CustomerName; -- This should be done after moving CustomerName data to the Customers table
ALTER TABLE OrderDetails ADD COLUMN CustomerID INT;

-- Filling CustomerID in OrderDetails would require a JOIN operation and might look something like this:
UPDATE OrderDetails o
SET o.CustomerID = c.CustomerID
FROM Customers c
WHERE o.CustomerName = c.CustomerName;

-- After this, ensure you add a foreign key constraint to maintain data integrity:
ALTER TABLE OrderDetails ADD FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID);
