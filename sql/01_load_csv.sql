\copy customers   FROM 'data/customers.csv'   CSV HEADER;
\copy products    FROM 'data/products.csv'    CSV HEADER;
\copy orders      FROM 'data/orders.csv'      CSV HEADER;
\copy order_items FROM 'data/order_items.csv' CSV HEADER;
