
-- Нужно ускорить запросы ниже любыми способами
-- Можно менять текст самого запроса или добавилять новые индексы
-- Схему БД менять нельзя
-- В овете пришлите итоговый запрос и все что было создано для его ускорения

-- Задача 1 -----------------------------------------------------------------
-- ИСХОДНЫЙ ЗАПРОС
DECLARE @StartTime datetime2 = '2010-08-30 16:27';

SELECT TOP(5000) wl.SessionID, wl.ServerID, wl.UserName 
FROM Marketing.WebLog AS wl
WHERE wl.SessionStart >= @StartTime
ORDER BY wl.SessionStart, wl.ServerID;
GO

-- ПОЯСНЕНИЯ
/*
Для ускоения  был доален индекс специально для данного запроса.
Без запроса выполняются следующие операции: поиск по кластерному индексу в Primary Key - происходит полное сканирование по инедксу.
Однако выполнение операций по полям, которые используются в запросе при кластеризованном индексе primary key, будут долгими, т.к. быдет происходить перебор всех значений, 
но при использовании класстерного индекса.
Выходом из такой ситуации может служить использование индекса. Т.к. мы будем работать только с этим запросом, то индекс будет подбираться для оптимизации данного запроса.
Порядок действий:
1. where
2. order
3. select
Для первых двух определим индекс:
Create INDEX indwebLogInfo ON Marketing.WebLog (SessionStart, ServerID) 
Для конструкции where и order будет удобно использоваться индексация по полю SessionStart
Далее также в order будет использован индекс ServerID
Также можно оптимизировать обращение, включив в список листьев поля из SELCT: SessionID, UserName - для того, чтобы не совершать доп. операции по считыванию.
Тогда индекс будет выглядеть так:
Create INDEX indwebLogInfo ON Marketing.WebLog (SessionStart, ServerID) INCLUDE (SessionID, UserName)
Таким образом, мы оптимизировали индекс по времени, однако за счет include сильно увеличили занимаемое пространство индекса. 
Операции модификации также стали дольше засчет использования индексов (необходимо теперь обновлять индексы - тем более, записывать дублирующие данные в листья индекса по include, 
а поле UserName иммет массивный тип nvarchar(100))
Чтобы избежать проблемы с избытком хранения данных, то поля из select можно записать, как отдельные составляющие индекса. Это также может удорожить действия модификации, 
однако теперь памяти не будет заниматься так много. Получаем следующую запись оптимизированную по памяти:
Create INDEX indwebLogInfo ON Marketing.WebLog (SessionStart, ServerID, SessionID, UserName)
На самом деле, нам не важен порядок SessionID и UserName в запросе select (оптимизатор сам изменит порядок для большей оптимизации. 
Для того, чтобы запрос выполнялся оптимальнее по памяти и по времени относительно данного индекса, можно вынести SessionID в блок INCLUDE
Это поле INT - хранить его будет оптимальнее, чем хранить индекс (нам не важен его порядок, для select важны лишь значения)
Create INDEX indwebLogInfo ON Marketing.WebLog (SessionStart, ServerID, UserName) IN (SessionID)
Таким образом, мы получили индекс, при котором запрос будет выполняться наиболее оптимально по времени и по памяти (также не так сильно замедляются операции модификации)
Если же рассматривать оптимизацию только по времени - которая и задана в условии, то получим следующий индекс который больше не обращается к памяти для UserName:
Create INDEX indwebLogInfo ON Marketing.WebLog (SessionStart, ServerID) INCLUDE (SessionID, UserName)
*/

-- РЕЗУЛЬТАТ ВЫПОЛНЕНИЯ
Drop INDEX indwebLogInfo1 ON Marketing.WebLog
Create INDEX indwebLogInfo ON Marketing.WebLog (SessionStart, ServerID, UserName) IN (SessionID) -- оптимальный с точки зрения памяти
Create INDEX indwebLogInfo ON Marketing.WebLog (SessionStart, ServerID) INCLUDE (SessionID, UserName) -- оптимальный только для данного запроса по времени (НАШ ВАРИАНТ)

DECLARE @StartTime datetime2 = '2010-08-30 16:27';

SELECT TOP(5000) wl.SessionID, wl.ServerID, wl.UserName 
FROM Marketing.WebLog AS wl
WHERE wl.SessionStart >= @StartTime
ORDER BY wl.SessionStart, wl.ServerID;
GO



-- Задача 2 -----------------------------------------------------------------

-- ИСХОДНЫЙ ЗАПРОС
SELECT PostalCode, Country
FROM Marketing.PostalCode 
WHERE StateCode = 'KY'
ORDER BY StateCode, PostalCode;
GO

-- ПОЯСНЕНИЯ
/*
Порядок действий:
1. where
2. order
3. select
После операции where не имеет смысла использовать ORDER BY StateCode, здесь и так содержатся одни и те же значения - сортировка происходить не будет
Соответвенно запрос может быть оптимизирован до вида:
	SELECT PostalCode, Country
	FROM Marketing.PostalCode 
	WHERE StateCode = 'KY'
	ORDER BY PostalCode;
Чтобы оптимизировать запрос, стоит ввести индексы на поля StateCode, PostalCode, получим индекс:
ON Marketing.PostalCode(StateCode, PostalCode)
Теперь, как и выше. Чтобы оптимизировать запрос по времени можем добавить индекс по Country
ON Marketing.PostalCode(StateCode, PostalCode, Country)
Но теперь такой вариант не приведет к оптимизации по памяти, ведь Country занимает 3 байта (Varchar(3)), сам индекс стоит дороже
Значит, по причине того, что Country используется только в select, стоит его вынести в блок INCLUDE - таким образом, запрос будет оптимизирован
и по скорости и по памяти, не будет необходимости отдельно производить считывания данных по Country с индекса
Create INDEX indPostalCode_Info ON Marketing.PostalCode(StateCode, PostalCode) INCLUDE (Country)
*/

-- РЕЗУЛЬТАТ ВЫПОЛНЕНИЯ
Create INDEX indPostalCode_Info ON Marketing.PostalCode(StateCode, PostalCode) INCLUDE (Country)  -- оптимазиация по скорости (с дополнительной оптимизацией по памяти, положитено сказывающейся на скорости)

SELECT PostalCode, Country
FROM Marketing.PostalCode 
WHERE StateCode = 'KY'
ORDER BY PostalCode;
GO

-- Задача 3 -----------------------------------------------------------------

-- ИСХОДНЫЙ ЗАПРОС

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


-- ПОЯСНЕНИЯ
/*
Для оптимизации первого запроса в цикле был выбран Индекс:
ind_ProspectName ON Marketing.Prospect (LastName, FirstName)
Использование именно такого индекса обусловлено наличием условия сравнения при внутреннем соединении 
ON p.LastName = sp.LastName
Таким образом в индексе первым должно идти поле LastName
Далее просходит сортировка по LastName и FirstName - для них также стоит ввести индексы.
Можно заменить, что таблица Salesperson имеет мало строк, в то время как Prospect имеет огромное количество.
Для оптимизации имеется следующий вариант:
 Вместо того, чтобы производить просмотр индекса LastName Marketing.Prospect,  а далее производить поиск по некластеному индексу LastName в таблице Marketing.Salesperson
 Можно прибегнуть к умному агрегированию (stream agregate). Балгодаря тому, что данные в индексе отсортированы, мы можем произвести просмотр для каждого Marketing.Prospect
 По данному индексу есть ли Marketing.Salesperson с таким же LastName - в реальности такой подход ускорит запрос.
 Таким образом, первый запрос будет выглядеть так:
  SELECT p.LastName, p.FirstName 
  FROM Marketing.Prospect AS p
  where p.LastName IN 
  (SELECT sp.LastName FROM  Marketing.Salesperson AS sp)
  ORDER BY p.LastName, p.FirstName;
Важный момент:
Мы также должны ввести некластерный индекс на поле LastName, по которому происходит соединение. Если не сделать этого, то Stream agreagate будет заменен на
Сортировку, что плохо скажется на скорости выполнения запроса.

Индекс indProspectName положительно скажется и на второй запрос, т.к. там происходит поиск по полю LastName. Далее происходит извлечение всех данных, по найденному полю.
Ввод дополнительны полей может пагубно сказиться на извлечение данных. Поэтому - наиболее оптимальным вариантом является вложенный цикл c Primary key с извлечением всех данных.

Неизвестно -  неизменяемые данные или нет в момент запроса. Однако, если данные неизменяемы, то удобной практикой было бы создание временных таблиц для каждого из запросов.
В цикле буут выводиться лишь результаты.
Далее таблицы будут удалены.

Важный момент: из-за того что в цикле результаты запроса кэшируются, то если выполнить запрос 1 раз и время будет, предположим, 0.1 сек, то это не значит,
что при выполнении данного запроса 500 раз - время будет 50 секунд. Скорее всего, такое выполнение будет происходить очень долго
*/


-- РЕЗУЛЬТАТ ВЫПОЛНЕНИЯ

-- создание индексов
CREATE INDEX indProspect_Name ON Marketing.Prospect (LastName, FirstName)
CREATE INDEX indSalesperson_Name ON Marketing.Salesperson (LastName)

-- выполнение 1-ого запроса с записью во временную таблицу tempTable1 
SELECT p.LastName, p.FirstName into #tempTable1 
  FROM Marketing.Prospect AS p
  where p.LastName IN 
  (SELECT sp.LastName FROM  Marketing.Salesperson AS sp)
  ORDER BY p.LastName, p.FirstName;

-- выполнение 2-ого запроса с записью во временную таблицу tempTable1 
SELECT * into #tempTable2
FROM Marketing.Prospect AS p
WHERE p.LastName = 'Smith';

-- выполнение цикла вывода данных
DECLARE @Counter INT = 0;
WHILE @Counter < 350
BEGIN
  SELECT * from #tempTable1
 
  SET @Counter += 1;
END;

-- удаление временных таблиц за ненадобностью
DROP TABLE #tempTable1 
DROP TABLE #tempTable2

-- Задача 4 -----------------------------------------------------------------

-- ИСХОДНЫЙ ЗАПРОС
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


-- ПОЯСНЕНИЯ
/*
Проблематика запроса состоит в том, что применяемые операции являются дорогими. Из-за малого количества данных проблемы выполнения не так сильно ощутимы, как при больших.
Было создано два решения - одно оптимизирует выполнение запроса при заданных данных, другое направлено на удешевение отдельных действий - такой вариант подойдет в тех случаях, 
когда на выходе мы имеем много значений. Конечные операции стандартного запроса имеют огромные вычислительные ресурсы.
*/

-- РЕЗУЛЬТАТ ВЫПОЛНЕНИЯ

-- ПЕРВЫЙ ВАРИАНТ - ОПТИМИЗАЦИЯ ДЛЯ ЗАДАННЫХ ДАННЫХ
/*
Первое решение различается лишь тем, что мы не таскаем хвост ProductModel, а присоединяем product ProductModel в конце. Таким образом, основные действия выполняются для меньшего 
количества строк.
К сожалению, из-за join разных таблиц, а также groupBy разных колонок, использование индексов практически ничего не дает. Рентабельным является создание индексов на поля,
по которым происходит соединение - таким образом, мы прийдем к поиску в индексе по этим полям (а не скан кластеризованного индекса)
*/

Create index indProduct_ProductSubcategoryID on Marketing.Product (SubCategoryID, ProductModelID) -- для соединения Product и Subcategory
Create index indSubcategory_SubcategoryCategoryID on Marketing.Subcategory (CategoryID) INCLUDE (SubcategoryName) --  для соединения Subcategory и Category

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

-- ВТОРОЙ ВАРИАНТ - ОПТИМИЗАЦИЯ СЛОЖНОСТИ
/*
В данном случае, реальная группировка производится только для product, там же мы можем отбросить те варианты, у которых count<=1
Далее мы акуратнно разворачиваем цепочку, используя оптимальные операции.
На самом деле, принцип выполнения запроса является наиболее оптимальным.
Если к представленному ниже запросу не добавлять индексы, то время выполнения будет одинаковым.
Для оптимизации запроса достаточно уже использовавшегося индеса:
Create index indProduct_ProductSubcategoryID on Marketing.Product (SubCategoryID, ProductModelID) 
Он необходим для оптимизации первой группировки
*/

Create index indProduct_ProductSubcategoryID on Marketing.Product (SubCategoryID, ProductModelID) -- для соединения Product и Subcategory

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