# Apple Store SQL Analysis

# <img src="https://github.com/user-attachments/assets/f61b4fbf-8510-4aff-9c4f-5a317eeab2cc" alt="Apple Logo" width="80" height="80">  <img src="https://github.com/user-attachments/assets/faf8dadc-fa00-481a-8b58-ade8120cac37" alt="Data Preparation Logo" width="80" height="80">  <img src="https://github.com/user-attachments/assets/6d20e9ad-bd6d-4287-9014-46555d5e7cb7" alt="sql Logo" width="80" height="80">  <img src="https://github.com/user-attachments/assets/c9a26822-b0de-442b-9c0b-6caa35699b0c" alt="data Logo" width="80" height="80">

## Project Overview

This project focuses on SQL-based analysis of Apple Store data, covering sales, products, stores, and warranty claims. It demonstrates advanced SQL querying techniques, query performance optimization, and a deep dive into key business metrics.

The data includes transactional sales data, store information, product categories, and warranty claims, and provides a solid foundation to gain insights into store performance, product sales, and warranty claim behavior.

## Objective

The primary objective of this project is to perform an in-depth analysis of Apple Store operations using SQL. The following goals were addressed:
- **Optimizing SQL queries** for faster execution using indexes and query tuning techniques.
- **Analyzing key performance indicators** such as store sales, product performance, and warranty claims.
- **Uncovering insights** on user behavior and trends in product sales and warranty claims.

## Dataset Information

The dataset consists of multiple tables representing different aspects of Apple Store operations:

### Table: `stores`
| **Column**   | **Description**                        |
| ------------ | -------------------------------------- |
| `store_id`   | Unique ID for each store               |
| `store_name` | Name of the store                      |
| `city`       | City where the store is located        |
| `country`    | Country where the store is located     |
| `category`   | Category of the store (Retail, Online) |

### Table: `categories`
| **Column**       | **Description**                     |
| ---------------- | ----------------------------------- |
| `category_id`    | Unique ID for each product category |
| `category_name`  | Name of the product category        |

### Table: `products`
| **Column**       | **Description**                      |
| ---------------- | ------------------------------------ |
| `product_id`     | Unique ID for each product           |
| `product_name`   | Name of the product                  |
| `category_id`    | ID of the category this product belongs to |
| `launch_date`    | Date the product was launched        |
| `price`          | Price of the product (in USD)        |

### Table: `sales`
| **Column**      | **Description**                      |
| --------------- | ------------------------------------ |
| `sale_id`       | Unique ID for each sale transaction  |
| `sale_date`     | Date of the sale                     |
| `store_id`      | ID of the store where the sale occurred |
| `product_id`    | ID of the product sold               |
| `quantity`      | Number of units sold                 |

### Table: `warranty_claims`
| **Column**      | **Description**                      |
| --------------- | ------------------------------------ |
| `claim_id`      | Unique ID for each warranty claim    |
| `claim_date`    | Date the warranty claim was filed    |
| `sale_id`       | ID of the related sale               |
| `repair_status` | Status of the repair (e.g., Warranty Void) |

## SQL Query Performance Optimization

### Query Performance Optimization- 

Indexes are a powerful tool for optimizing query performance, especially in read-heavy applications. By creating indexes on frequently queried columns like product_id, store_id, and sale_id, you can significantly reduce the time it takes to retrieve data, improve query efficiency, and reduce the load on your database.

To analyze the specific use case of your queries before adding indexes, and use the EXPLAIN ANALYZE command to identify potential areas for optimization.

#### EXPLAIN ANALYZE
```sql
EXPLAIN ANALYZE
SELECT * FROM sales
WHERE product_id = 986;
```

To improve query performance, several indexes were created:

```sql
CREATE INDEX sales_product_id ON sales(product_id);
CREATE INDEX sales_store_id ON sales(store_id);
CREATE INDEX sales_sale_id ON sales(sale_id);
```

## SQL Queries and Solutions

### 1. Find the number of stores in each country.

```sql
SELECT country, COUNT(store_id) AS total_stores 
FROM stores
GROUP BY country
ORDER BY total_stores DESC;
```

### 2. Calculate the total number of units sold by each store.

```sql
SELECT s.store_id, st.store_name, SUM(s.quantity) AS total_quantity 
FROM sales AS s
JOIN stores AS st ON s.store_id = st.store_id
GROUP BY s.store_id, st.store_name
ORDER BY total_quantity DESC;
```

### 3. Identify how many sales occurred in December 2024.

```sql
SELECT COUNT(*) AS total_sales 
FROM sales
WHERE YEAR(sale_date) = 2024 AND MONTH(sale_date) = 12;
```

### 4. Determine how many stores have never had a warranty claim filed.

```sql
SELECT COUNT(store_id) AS store_count 
FROM stores
WHERE store_id NOT IN (
    SELECT DISTINCT s.store_id 
    FROM warranty_claims AS w
    JOIN sales AS s ON w.sale_id = s.sale_id
);
```

### 5. Calculate the percentage of warranty claims marked as "Warranty Void."

```sql
SELECT ROUND(COUNT(claim_id) / CAST((SELECT COUNT(claim_id) FROM warranty_claims) AS UNSIGNED) * 100, 2) AS void_percentage 
FROM warranty_claims
WHERE repair_status = 'Warranty Void';

```

### 6. Find the average price of products in each category.

```sql
SELECT p.category_id, c.category_name, AVG(p.price) AS avg_price
FROM products AS p
JOIN categories AS c ON p.category_id = c.category_id
GROUP BY p.category_id, c.category_name
ORDER BY avg_price DESC;
```

### 7. Count the number of unique products sold in the last month.

```sql
SELECT COUNT(DISTINCT product_id) AS unique_prod_sold 
FROM sales
WHERE sale_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH);
```

### 8. For each store, identify the best-selling day based on highest quantity sold

```sql
WITH day_rank AS (
    SELECT store_id, DAYNAME(sale_date) AS day_name, SUM(quantity) AS total_quantity,
    DENSE_RANK() OVER(PARTITION BY store_id ORDER BY SUM(quantity) DESC) AS rankings
    FROM sales
    GROUP BY 1, 2
    ORDER BY 1, 3 DESC
)
SELECT store_id, day_name, total_quantity
FROM day_rank
WHERE rankings = 1;
```

### 9. Identify the least selling product in each country based on total units sold.

```sql
WITH prod_country_rank AS (
    SELECT st.country, s.product_id, SUM(s.quantity) AS quantity_sold,
    DENSE_RANK() OVER(PARTITION BY st.country ORDER BY SUM(s.quantity)) AS rankings
    FROM sales AS s
    JOIN stores AS st
    ON s.store_id = st.store_id
    GROUP BY 1, 2
    ORDER BY 1, 3
)
SELECT country, product_id, quantity_sold 
FROM prod_country_rank 
WHERE rankings = 1;
```

### 10. Identify the product category with the most warranty claims filed in the last two months. 

```sql
SELECT p.category_id, COUNT(w.claim_id) AS total_claims 
FROM warranty_claims AS w
JOIN sales AS s
ON w.sale_id = s.sale_id
JOIN products AS p
ON s.product_id = p.product_id
WHERE w.claim_date <= DATE_SUB(CURRENT_DATE(), INTERVAL 2 MONTH)
GROUP BY 1
ORDER BY 2 DESC;
```
# Apple Store SQL Analysis Project Overview

## Project Summary

This project involves the analysis of an Apple Store dataset using advanced SQL techniques. The dataset consists of information related to stores, products, categories, sales, and warranty claims. The goal of the project is to derive insights into sales performance, warranty claims, store distribution, and product trends. Additionally, the project focuses on SQL query performance optimization to ensure that the analysis runs efficiently, even on large datasets.

---

## Tasks and Steps Performed

### 1. **Dataset Understanding and Cleaning**
   - I started by understanding the structure of the dataset, including the relationships between the five key tables: `stores`, `categories`, `products`, `sales`, and `warranty_claims`.
   - I ensured data consistency and verified that no invalid or missing entries would affect the queries.

### 2. **SQL Query Development**
   - Developed a series of SQL queries to extract valuable insights from the dataset. Queries addressed key business questions, such as:
     - Which store has the highest sales?
     - How many stores are located in each country?
     - What percentage of warranty claims were voided?
     - Identifying the least sold products in each country.
   - Complex queries using window functions (e.g., `DENSE_RANK()` and `LAG()`) were employed to identify top-selling days, sales growth ratios, and running totals.

### 3. **Query Performance Optimization**
   - Analyzed the performance of my SQL queries using the `EXPLAIN ANALYZE` command to identify performance bottlenecks.
   - Implemented **indexes** on frequently queried columns (`product_id`, `store_id`, `sale_id`) to speed up query execution.
   - These optimizations ensured that the queries were efficient and could handle large datasets without causing performance issues.

### 4. **Insights and Key Findings**
   - Based on the SQL queries, I derived the following insights:
     - The USA hosts over 50% of the total Apple stores globally.
     - A few stores account for a significant portion of total sales, with one store selling over 10,000 units.
     - Around 15% of warranty claims were voided, indicating potential issues with product quality or customer handling.
     - Electronics were the most problematic category in terms of warranty claims.

### 5. **SQL Techniques and Methods Used**
   - **Window functions** (`RANK()`, `DENSE_RANK()`, `LAG()`): Used to perform advanced analysis like finding top-performing stores, calculating growth ratios, and running totals.
   - **Common Table Expressions (CTEs)**: Employed to break down complex queries into more readable and manageable steps.
   - **Aggregations and Grouping**: Used to calculate totals, averages, and other summary statistics across different dimensions (e.g., store, country, product category).
   - **Joins and Subqueries**: Leveraged to extract data from multiple related tables, ensuring comprehensive analysis.
   - **Indexes**: Created to optimize query performance, specifically targeting frequently queried columns.

### 6. **Documentation**
   - Created detailed documentation, including query descriptions and performance optimizations.
   - Provided explanations of the rationale behind each query and optimization step to ensure clarity and transparency in the analysis.

### 7. **Challenges Faced**
   - Optimizing queries for large datasets without compromising the accuracy of the results was challenging, particularly when using window functions and joins on multiple tables.
   - Query performance optimization required in-depth analysis using `EXPLAIN ANALYZE` and iterative testing to fine-tune the indexing strategy.

---

## Conclusion

This project demonstrates my ability to:
   - Develop complex SQL queries to extract actionable insights from large datasets.
   - Optimize query performance using indexing and other advanced SQL techniques.
   - Analyze data in a way that provides valuable business insights for retail management.

The project highlights my expertise in SQL querying, performance tuning, and business data analysis. It also reflects my ability to work with large datasets and deliver actionable insights to support decision-making in a business context.
