create database apple;

CREATE TABLE stores (
    store_id INT PRIMARY KEY,
    store_name VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    category VARCHAR(100) NOT NULL
);

CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(255) NOT NULL
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    category_id INT,
    launch_date DATE NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    sale_date DATE NOT NULL,
    store_id INT,
    product_id INT,
    quantity INT NOT NULL,
    FOREIGN KEY (store_id) REFERENCES stores(store_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE warranty_claims (
    claim_id INT PRIMARY KEY,
    claim_date DATE NOT NULL,
    sale_id INT,
    repair_status VARCHAR(100) NOT NULL,
    FOREIGN KEY (sale_id) REFERENCES sales(sale_id)
);
