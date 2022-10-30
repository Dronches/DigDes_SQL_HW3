
-- ����� �������� ������� ���� ������ ���������
-- ����� ������ ����� ������ ������� ��� ���������� ����� �������
-- ����� �� ������ ������
-- � ����� �������� �������� ������ � ��� ��� ���� ������� ��� ��� ���������

-- ������ 1 -----------------------------------------------------------------
-- �������� ������
DECLARE @StartTime datetime2 = '2010-08-30 16:27';

SELECT TOP(5000) wl.SessionID, wl.ServerID, wl.UserName 
FROM Marketing.WebLog AS wl
WHERE wl.SessionStart >= @StartTime
ORDER BY wl.SessionStart, wl.ServerID;
GO

-- ���������
/*
��� ��������  ��� ������ ������ ���������� ��� ������� �������.
��� ������� ����������� ��������� ��������: ����� �� ����������� ������� � Primary Key - ���������� ������ ������������ �� �������.
������ ���������� �������� �� �����, ������� ������������ � ������� ��� ���������������� ������� primary key, ����� �������, �.�. ����� ����������� ������� ���� ��������, 
�� ��� ������������� ������������ �������.
������� �� ����� �������� ����� ������� ������������� �������. �.�. �� ����� �������� ������ � ���� ��������, �� ������ ����� ����������� ��� ����������� ������� �������.
������� ��������:
1. where
2. order
3. select
��� ������ ���� ��������� ������:
Create INDEX indwebLogInfo ON Marketing.WebLog (SessionStart, ServerID) 
��� ����������� where � order ����� ������ �������������� ���������� �� ���� SessionStart
����� ����� � order ����� ����������� ������ ServerID
����� ����� �������������� ���������, ������� � ������ ������� ���� �� SELCT: SessionID, UserName - ��� ����, ����� �� ��������� ���. �������� �� ����������.
����� ������ ����� ��������� ���:
Create INDEX indwebLogInfo ON Marketing.WebLog (SessionStart, ServerID) INCLUDE (SessionID, UserName)
����� �������, �� �������������� ������ �� �������, ������ �� ���� include ������ ��������� ���������� ������������ �������. 
�������� ����������� ����� ����� ������ ������ ������������� �������� (���������� ������ ��������� ������� - ��� �����, ���������� ����������� ������ � ������ ������� �� include, 
� ���� UserName ����� ��������� ��� nvarchar(100))
����� �������� �������� � �������� �������� ������, �� ���� �� select ����� ��������, ��� ��������� ������������ �������. ��� ����� ����� ��������� �������� �����������, 
������ ������ ������ �� ����� ���������� ��� �����. �������� ��������� ������ ���������������� �� ������:
Create INDEX indwebLogInfo ON Marketing.WebLog (SessionStart, ServerID, SessionID, UserName)
�� ����� ����, ��� �� ����� ������� SessionID � UserName � ������� select (����������� ��� ������� ������� ��� ������� �����������. 
��� ����, ����� ������ ���������� ����������� �� ������ � �� ������� ������������ ������� �������, ����� ������� SessionID � ���� INCLUDE
��� ���� INT - ������� ��� ����� �����������, ��� ������� ������ (��� �� ����� ��� �������, ��� select ����� ���� ��������)
Create INDEX indwebLogInfo ON Marketing.WebLog (SessionStart, ServerID, UserName) IN (SessionID)
����� �������, �� �������� ������, ��� ������� ������ ����� ����������� �������� ���������� �� ������� � �� ������ (����� �� ��� ������ ����������� �������� �����������)
���� �� ������������� ����������� ������ �� ������� - ������� � ������ � �������, �� ������� ��������� ������ ������� ������ �� ���������� � ������ ��� UserName:
Create INDEX indwebLogInfo ON Marketing.WebLog (SessionStart, ServerID) INCLUDE (SessionID, UserName)
*/

-- ��������� ����������
Drop INDEX indwebLogInfo1 ON Marketing.WebLog
Create INDEX indwebLogInfo ON Marketing.WebLog (SessionStart, ServerID, UserName) IN (SessionID) -- ����������� � ����� ������ ������
Create INDEX indwebLogInfo ON Marketing.WebLog (SessionStart, ServerID) INCLUDE (SessionID, UserName) -- ����������� ������ ��� ������� ������� �� ������� (��� �������)

DECLARE @StartTime datetime2 = '2010-08-30 16:27';

SELECT TOP(5000) wl.SessionID, wl.ServerID, wl.UserName 
FROM Marketing.WebLog AS wl
WHERE wl.SessionStart >= @StartTime
ORDER BY wl.SessionStart, wl.ServerID;
GO



-- ������ 2 -----------------------------------------------------------------

-- �������� ������
SELECT PostalCode, Country
FROM Marketing.PostalCode 
WHERE StateCode = 'KY'
ORDER BY StateCode, PostalCode;
GO

-- ���������
/*
������� ��������:
1. where
2. order
3. select
����� �������� where �� ����� ������ ������������ ORDER BY StateCode, ����� � ��� ���������� ���� � �� �� �������� - ���������� ����������� �� �����
������������ ������ ����� ���� ������������� �� ����:
	SELECT PostalCode, Country
	FROM Marketing.PostalCode 
	WHERE StateCode = 'KY'
	ORDER BY PostalCode;
����� �������������� ������, ����� ������ ������� �� ���� StateCode, PostalCode, ������� ������:
ON Marketing.PostalCode(StateCode, PostalCode)
������, ��� � ����. ����� �������������� ������ �� ������� ����� �������� ������ �� Country
ON Marketing.PostalCode(StateCode, PostalCode, Country)
�� ������ ����� ������� �� �������� � ����������� �� ������, ���� Country �������� 3 ����� (Varchar(3)), ��� ������ ����� ������
������, �� ������� ����, ��� Country ������������ ������ � select, ����� ��� ������� � ���� INCLUDE - ����� �������, ������ ����� �������������
� �� �������� � �� ������, �� ����� ������������� �������� ����������� ���������� ������ �� Country � �������
Create INDEX indPostalCode_Info ON Marketing.PostalCode(StateCode, PostalCode) INCLUDE (Country)
*/

-- ��������� ����������
Create INDEX indPostalCode_Info ON Marketing.PostalCode(StateCode, PostalCode) INCLUDE (Country)  -- ������������ �� �������� (� �������������� ������������ �� ������, ���������� ������������� �� ��������)

SELECT PostalCode, Country
FROM Marketing.PostalCode 
WHERE StateCode = 'KY'
ORDER BY PostalCode;
GO

-- ������ 3 -----------------------------------------------------------------

-- �������� ������

DECLARE @Counter INT = 0;
WHILE @Counter < 350
BEGIN
  SELECT p.LastName, p.FirstName 
  FROM Marketing.Prospect AS p
  INNER JOIN Marketing.Salesperson AS sp
  ON p.LastName = sp.LastName
  ORDER BY p.LastName, p.FirstName;
  
  SELECT * 
  FROM Marketing.Prospect AS p
  WHERE p.LastName = 'Smith';
  SET @Counter += 1;
END;


-- ���������
/*
��� ����������� ������� ������� � ����� ��� ������ ������:
ind_ProspectName ON Marketing.Prospect (LastName, FirstName)
������������� ������ ������ ������� ����������� �������� ������� ��������� ��� ���������� ���������� 
ON p.LastName = sp.LastName
����� ������� � ������� ������ ������ ���� ���� LastName
����� ��������� ���������� �� LastName � FirstName - ��� ��� ����� ����� ������ �������.
����� ��������, ��� ������� Salesperson ����� ���� �����, � �� ����� ��� Prospect ����� �������� ����������.
��� ����������� ������� ��������� �������:
 ������ ����, ����� ����������� �������� ������� LastName Marketing.Prospect,  � ����� ����������� ����� �� ������������ ������� LastName � ������� Marketing.Salesperson
 ����� ���������� � ������ ������������� (stream agregate). ��������� ����, ��� ������ � ������� �������������, �� ����� ���������� �������� ��� ������� Marketing.Prospect
 �� ������� ������� ���� �� Marketing.Salesperson � ����� �� LastName - � ���������� ����� ������ ������� ������.
 ����� �������, ������ ������ ����� ��������� ���:
  SELECT p.LastName, p.FirstName 
  FROM Marketing.Prospect AS p
  where p.LastName IN 
  (SELECT sp.LastName FROM  Marketing.Salesperson AS sp)
  ORDER BY p.LastName, p.FirstName;
������ ������:
�� ����� ������ ������ ������������ ������ �� ���� LastName, �� �������� ���������� ����������. ���� �� ������� �����, �� Stream agreagate ����� ������� ��
����������, ��� ����� �������� �� �������� ���������� �������.

������ indProspectName ������������ �������� � �� ������ ������, �.�. ��� ���������� ����� �� ���� LastName. ����� ���������� ���������� ���� ������, �� ���������� ����.
���� ������������� ����� ����� ������� ��������� �� ���������� ������. ������� - �������� ����������� ��������� �������� ��������� ���� c Primary key � ����������� ���� ������.

���������� -  ������������ ������ ��� ��� � ������ �������. ������, ���� ������ �����������, �� ������� ��������� ���� �� �������� ��������� ������ ��� ������� �� ��������.
� ����� ���� ���������� ���� ����������.
����� ������� ����� �������.

������ ������: ��-�� ���� ��� � ����� ���������� ������� ����������, �� ���� ��������� ������ 1 ��� � ����� �����, �����������, 0.1 ���, �� ��� �� ������,
��� ��� ���������� ������� ������� 500 ��� - ����� ����� 50 ������. ������ �����, ����� ���������� ����� ����������� ����� �����
*/


-- ��������� ����������

-- �������� ��������
CREATE INDEX indProspect_Name ON Marketing.Prospect (LastName, FirstName)
CREATE INDEX indSalesperson_Name ON Marketing.Salesperson (LastName)

-- ���������� 1-��� ������� � ������� �� ��������� ������� tempTable1 
SELECT p.LastName, p.FirstName into #tempTable1 
  FROM Marketing.Prospect AS p
  where p.LastName IN 
  (SELECT sp.LastName FROM  Marketing.Salesperson AS sp)
  ORDER BY p.LastName, p.FirstName;

-- ���������� 2-��� ������� � ������� �� ��������� ������� tempTable1 
SELECT * into #tempTable2
FROM Marketing.Prospect AS p
WHERE p.LastName = 'Smith';

-- ���������� ����� ������ ������
DECLARE @Counter INT = 0;
WHILE @Counter < 350
BEGIN
  SELECT * from #tempTable1
 
  SET @Counter += 1;
END;

-- �������� ��������� ������ �� �������������
DROP TABLE #tempTable1 
DROP TABLE #tempTable2

-- ������ 4 -----------------------------------------------------------------

-- �������� ������
SELECT
	c.CategoryName,
	sc.SubcategoryName,
	pm.ProductModel,
	COUNT(p.ProductID) AS ModelCount
FROM Marketing.ProductModel pm
	JOIN Marketing.Product p
		ON p.ProductModelID = pm.ProductModelID
	JOIN Marketing.Subcategory sc
		ON sc.SubcategoryID = p.SubcategoryID
	JOIN Marketing.Category c
		ON c.CategoryID = sc.CategoryID
GROUP BY c.CategoryName,
	sc.SubcategoryName,
	pm.ProductModel
HAVING COUNT(p.ProductID) > 1


-- ���������
/*
������������ ������� ������� � ���, ��� ����������� �������� �������� ��������. ��-�� ������ ���������� ������ �������� ���������� �� ��� ������ �������, ��� ��� �������.
���� ������� ��� ������� - ���� ������������ ���������� ������� ��� �������� ������, ������ ���������� �� ���������� ��������� �������� - ����� ������� �������� � ��� �������, 
����� �� ������ �� ����� ����� ��������. �������� �������� ������������ ������� ����� �������� �������������� �������.
*/

-- ��������� ����������

-- ������ ������� - ����������� ��� �������� ������
/*
������ ������� ����������� ���� ���, ��� �� �� ������� ����� ProductModel, � ������������ product ProductModel � �����. ����� �������, �������� �������� ����������� ��� �������� 
���������� �����.
� ���������, ��-�� join ������ ������, � ����� groupBy ������ �������, ������������� �������� ����������� ������ �� ����. ������������ �������� �������� �������� �� ����,
�� ������� ���������� ���������� - ����� �������, �� ������� � ������ � ������� �� ���� ����� (� �� ���� ����������������� �������)
*/

Create index indProduct_ProductSubcategoryID on Marketing.Product (SubCategoryID, ProductModelID) -- ��� ���������� Product � Subcategory
Create index indSubcategory_SubcategoryCategoryID on Marketing.Subcategory (CategoryID) INCLUDE (SubcategoryName) --  ��� ���������� Subcategory � Category

DROP index indProduct_ProductSubcategoryID on Marketing.Product 
DROP index indSubcategory_SubcategoryCategoryID on Marketing.Subcategory 

SELECT CategoryName,
	SubcategoryName,
	pm.ProductModel,
	 ModelCount
FROM (
SELECT
	c.CategoryName,
	sc.SubcategoryName,
	p.ProductModelID,
	COUNT(p.ProductID) AS ModelCount
FROM Marketing.Product p
	JOIN Marketing.Subcategory sc
		ON sc.SubcategoryID = p.SubcategoryID
	JOIN Marketing.Category c
		ON c.CategoryID = sc.CategoryID
GROUP BY c.CategoryName,
	sc.SubcategoryName,
	p.ProductModelID
HAVING COUNT(p.ProductID) > 1
) as A
join Marketing.ProductModel as pm
on A.ProductModelID = pm.ProductModelID

-- ������ ������� - ����������� ���������
/*
� ������ ������, �������� ����������� ������������ ������ ��� product, ��� �� �� ����� ��������� �� ��������, � ������� count<=1
����� �� ��������� ������������� �������, ��������� ����������� ��������.
�� ����� ����, ������� ���������� ������� �������� �������� �����������.
���� � ��������������� ���� ������� �� ��������� �������, �� ����� ���������� ����� ����������.
��� ����������� ������� ���������� ��� ����������������� ������:
Create index indProduct_ProductSubcategoryID on Marketing.Product (SubCategoryID, ProductModelID) 
�� ��������� ��� ����������� ������ �����������
*/

Create index indProduct_ProductSubcategoryID on Marketing.Product (SubCategoryID, ProductModelID) -- ��� ���������� Product � Subcategory

SELECT CategoryName,
	SubcategoryName,
	pm.ProductModel,
	 ModelCount
	 FROM 
(
Select CategoryID, SubcategoryName, ProductModelID, sum(ModelCount) as ModelCount
FROM
(
Select p.SubcategoryID, p.ProductModelID, COUNT(p.ProductID) AS ModelCount
From
Marketing.Product as p
group by p.SubcategoryID, p.ProductModelID
Having COUNT(p.ProductID) > 1
) as p
JOIN Marketing.Subcategory sc
	ON sc.SubcategoryID = p.SubcategoryID
	group by sc.SubcategoryName, sc.CategoryID, ProductModelID 
	) as sc
JOIN Marketing.Category as c
	ON c.CategoryID = sc.CategoryID
join Marketing.ProductModel as pm
on sc.ProductModelID = pm.ProductModelID