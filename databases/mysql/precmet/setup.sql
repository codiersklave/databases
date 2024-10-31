drop schema if exists `precmet`;
drop schema if exists `metalwise`;
create schema `metalwise` default charset=utf8mb4 collate=utf8mb4_general_ci;
use `metalwise`;

set names 'utf8mb4';
set foreign_key_checks = 0;

create table `price` (
    `id` int unsigned not null auto_increment, -- Primary key
    `_v` int unsigned not null default 1, -- Version column for optimistic locking
    
    `product_id` int unsigned not null, -- Foreign key to `product` table
    
    `date` datetime not null, -- Date when the price is recorded
    `price_in_cents` int unsigned not null, -- Price of the product in cents
    
    `created` datetime not null default current_timestamp(), -- Timestamp when the record is created
    `updated` datetime not null default current_timestamp() on update current_timestamp(), -- Timestamp when the record is updated
    `deleted` datetime default null, -- Timestamp when the record is marked as deleted
    
    primary key (`id`),
    foreign key (`product_id`) references `product` (`id`)
) engine=innodb;

create table `_price` (
    `id` int unsigned not null, -- Price id
    `_v` int unsigned not null, -- Version number
    
    `product_id` int unsigned not null, -- Foreign key to `product` table
    
    `date` datetime not null, -- Date when the price is recorded
    `price_in_cents` int unsigned not null, -- Price of the product in cents
    
    `created` datetime not null, -- Timestamp when the record is created
    `updated` datetime not null, -- Timestamp when the record is updated
    `deleted` datetime null, -- Timestamp when the record is marked as deleted
    
    primary key (`id`, `_v`),
    foreign key (`id`) references `price` (`id`) on delete cascade
) engine=innodb;

create table `product` (
    `id` int unsigned not null auto_increment, -- Primary key
    `_v` int unsigned not null default 1, -- Version column for optimistic locking
    
    `parent_id` int unsigned default null, -- Parent product id, represents hierarchy
    
    `name` varchar(255) not null unique, -- Name of the product
    `multiplier` float unsigned not null default 1, -- Multiplier for the product
    
    `created` datetime not null default current_timestamp(), -- Timestamp when the record is created
    `updated` datetime not null default current_timestamp() on update current_timestamp(), -- Timestamp when the record is updated
    `deleted` datetime default null, -- Timestamp when the record is marked as deleted
    
    primary key (`id`),
    foreign key (`parent_id`) references `product` (`id`)
) engine=innodb;

create table `_product` (
    `id` int unsigned not null, -- Product id
    `_v` int unsigned not null, -- Version number
    
    `parent_id` int unsigned null, -- Parent product id
    
    `name` varchar(255) not null, -- Name of the product
    `multiplier` float unsigned not null, -- Multiplier for the product
    
    `created` datetime not null, -- Timestamp when the record is created
    `updated` datetime not null, -- Timestamp when the record is updated
    `deleted` datetime null, -- Timestamp when the record is marked as deleted
    
    primary key (`id`, `_v`),
    foreign key (`id`) references `product` (`id`) on delete cascade
) engine=innodb;

create table `purchase` (
    `id` int unsigned not null auto_increment, -- Primary key
    `_v` int unsigned not null default 1, -- Version column for optimistic locking
    
    `product_id` int unsigned not null, -- Foreign key to `product` table
    
    `date` date not null, -- Date of the purchase
    `quantity` int unsigned not null, -- Quantity of the product purchased
    `total_price_in_cents` int unsigned not null, -- Total price of the purchase in cents
    `included_costs_in_cents` int unsigned not null default 0, -- Included additional costs in cents
    
    `created` datetime not null default current_timestamp(), -- Timestamp when the record is created
    `updated` datetime not null default current_timestamp() on update current_timestamp(), -- Timestamp when the record is updated
    `deleted` datetime default null, -- Timestamp when the record is marked as deleted
    
    primary key (`id`),
    foreign key (`product_id`) references `product` (`id`)
) engine=innodb;

create table `_purchase` (
    `id` int unsigned not null, -- Purchase id
    `_v` int unsigned not null, -- Version number
    
    `product_id` int unsigned not null, -- Foreign key to `product` table
    
    `date` date not null, -- Date of the purchase
    `quantity` int unsigned not null, -- Quantity of the product purchased
    `total_price_in_cents` int unsigned not null, -- Total price of the purchase in cents
    `included_costs_in_cents` int unsigned not null, -- Included additional costs in cents
    
    `created` datetime not null, -- Timestamp when the record is created
    `updated` datetime not null, -- Timestamp when the record is updated
    `deleted` datetime null, -- Timestamp when the record is marked as deleted
    
    primary key (`id`, `_v`),
    foreign key (`id`) references `purchase` (`id`) on delete cascade
) engine=innodb;

delimiter //

-- Trigger to increment version number before updating `price`
create trigger `price_before_update` before update on `price` for each row begin 
    set new.`_v` = old.`_v` + 1;
end //

-- Trigger to insert old version into `_price` after updating `price`
create trigger `price_after_update` after update on `price` for each row begin
    insert into `_price` (`id`, `_v`, `product_id`, `date`, `price_in_cents`, `created`, `updated`, `deleted`)
    values (old.`id`, old.`_v`, old.`product_id`, old.`date`, old.`price_in_cents`, old.`created`, old.`updated`, old.`deleted`);
end //

-- Trigger to prevent deletion of `price` records and suggest setting `deleted` column instead
create trigger `price_before_delete` before delete on `price` for each row begin
    if @allow_deletion is null or @allow_deletion = false then
        signal sqlstate '45000'
        set message_text = 'Records in this table cannot be deleted. Set the `deleted` date to the current date instead.';
    end if;
end //

-- Trigger to reset the deletion flag after deleting in `price`
create trigger `price_after_delete` after delete on `price` for each row begin 
    set @allow_deletion = false;
end //

-- Trigger to increment version number before updating `product`
create trigger `product_before_update` before update on `product` for each row begin 
    set new.`_v` = old.`_v` + 1;
end //

-- Trigger to insert old version into `_product` after updating `product`
create trigger `product_after_update` after update on `product` for each row begin
    insert into `_product` (`id`, `_v`, `parent_id`, `name`, `multiplier`, `created`, `updated`, `deleted`)
    values (old.`id`, old.`_v`, old.`parent_id`, old.`name`, old.`multiplier`, old.`created`, old.`updated`, old.`deleted`);
end //

-- Trigger to prevent deletion of `product` records and suggest setting `deleted` column instead
create trigger `product_before_delete` before delete on `product` for each row begin
    if @allow_deletion is null or @allow_deletion = false then
        signal sqlstate '45000'
        set message_text = 'Records in this table cannot be deleted. Set the `deleted` date to the current date instead.';
    end if;
end //

-- Trigger to reset the deletion flag after deleting in `product`
create trigger `product_after_delete` after delete on `product` for each row begin 
    set @allow_deletion = false;
end //

-- Trigger to increment version number before updating `purchase`
create trigger `purchase_before_update` before update on `purchase` for each row begin 
    set new.`_v` = old.`_v` + 1;
end //

-- Trigger to insert old version into `_purchase` after updating `purchase`
create trigger `purchase_after_update` after update on `purchase` for each row begin
    insert into `_purchase` (`id`, `_v`, `product_id`, `date`, `quantity`, `total_price_in_cents`, `included_costs_in_cents`, `created`, `updated`, `deleted`)
    values (old.`id`, old.`_v`, old.`product_id`, old.`date`, old.`quantity`, old.`total_price_in_cents`, `included_costs_in_cents`, old.`created`, old.`updated`, old.`deleted`);
end //

-- Trigger to prevent deletion of `purchase` records and suggest setting `deleted` column instead
create trigger `purchase_before_delete` before delete on `purchase` for each row begin
    if @allow_deletion is null or @allow_deletion = false then
        signal sqlstate '45000'
        set message_text = 'Records in this table cannot be deleted. Set the `deleted` date to the current date instead.';
    end if;
end //

-- Trigger to reset the deletion flag after deleting in `purchase`
create trigger `purchase_after_delete` after delete on `purchase` for each row begin 
    set @allow_deletion = false;
end //

delimiter ;

set foreign_key_checks = 1;


-- Create a view to calculate average prices for non-root products
create view `derived_products_avg_prices_paid` as
with recursive product_hierarchy as (
    select
        id as product_id,
        id as root_parent_id,
        name as root_parent_name,
        parent_id
    from
        product
    where
        parent_id is null

    union all

    select
        p.id as product_id,
        ph.root_parent_id,
        ph.root_parent_name,
        p.parent_id
    from
        product p
    join
        product_hierarchy ph on p.parent_id = ph.product_id
)
select
    p.product_id,
    round(avg(p.total_price_in_cents / p.quantity)) as average_price_in_cents,
    sum(p.quantity) as total_quantity,
    pr.multiplier as product_multiplier,
    ph.root_parent_id,
    ph.root_parent_name,
    sum(p.quantity) * pr.multiplier as root_product_quantity,
    sum(p.total_price_in_cents) as total_product_price_in_cents
from
    purchase p
join
    product pr on p.product_id = pr.id
join
    product_hierarchy ph on pr.id = ph.product_id
where
    p.deleted is null
group by
   p.product_id, pr.multiplier, ph.root_parent_id, ph.root_parent_name;

create view `base_products_avg_prices_paid` as
select
    root_parent_id,
    root_parent_name,
    round(sum(total_product_price_in_cents) / sum(root_product_quantity)) as root_average_price_in_cents
from
    derived_products_avg_prices_paid
group by 
    root_parent_id, root_parent_name;

CREATE VIEW `base_products_current_values` AS
WITH latest_prices AS (
    SELECT p1.product_id, 
           p1.price_in_cents, 
           MAX(p1.date) as max_date
    FROM price p1
    JOIN (
        SELECT product_id, 
               MAX(date) as max_date
        FROM price
        GROUP BY product_id
    ) p2 ON p1.product_id = p2.product_id 
        AND p1.date = p2.max_date
    GROUP BY p1.product_id, p1.price_in_cents
)
SELECT latest.product_id,
       latest.price_in_cents AS current_price_in_cents,
       avg_price.root_average_price_in_cents,
       (latest.price_in_cents - avg_price.root_average_price_in_cents) AS price_difference_in_cents
FROM latest_prices latest
JOIN base_products_avg_prices_paid avg_price ON latest.product_id = avg_price.root_parent_id;

create view `base_products_current_difference` as
select
    cvrp.product_id,
    cvrp.price_difference_in_cents,
    sum(apnrp.root_product_quantity),
    round(cvrp.price_difference_in_cents * sum(apnrp.root_product_quantity)) as `total_difference`
from
    base_products_current_values as cvrp
left join
    derived_products_avg_prices_paid as apnrp on apnrp.root_parent_id = cvrp.product_id 
group by 
    cvrp.product_id,
    cvrp.price_difference_in_cents;

CREATE VIEW `derived_products_current_values` AS
WITH latest_prices AS (
    SELECT p1.product_id, 
           p1.price_in_cents, 
           MAX(p1.date) as max_date
    FROM price p1
    JOIN (
        SELECT product_id, 
               MAX(date) as max_date
        FROM price
        GROUP BY product_id
    ) p2 ON p1.product_id = p2.product_id 
        AND p1.date = p2.max_date
    GROUP BY p1.product_id, p1.price_in_cents
)
SELECT latest.product_id,
       latest.price_in_cents AS current_price_in_cents,
       avg_price.average_price_in_cents,
       (latest.price_in_cents - avg_price.average_price_in_cents) AS price_difference_in_cents
FROM latest_prices latest
JOIN derived_products_avg_prices_paid avg_price ON latest.product_id = avg_price.product_id;

create view `derived_products_current_difference` as
SELECT
    cvnrp.product_id,
    cvnrp.price_difference_in_cents,
    sum(apnrp.total_quantity) as total_quantity,
    round(cvnrp.price_difference_in_cents * sum(apnrp.total_quantity)) as total_difference
FROM
    derived_products_current_values as cvnrp
LEFT JOIN
    derived_products_avg_prices_paid as apnrp on apnrp.product_id = cvnrp.product_id
GROUP BY 
    cvnrp.product_id,
    cvnrp.price_difference_in_cents;

create view `base_products_current_total_difference` as
select sum(`total_difference`) as `total_difference` from base_products_current_difference;

create view `derived_products_current_total_difference` as
select sum(`total_difference`) as `total_difference` from derived_products_current_difference;


create view `current_total_differences` as
select
    'Non-Root Products' as `name`,
    `total_difference`
from
    `derived_products_current_total_difference`
union
select
    'Root Products' as `name`,
    `total_difference`
from
    `base_products_current_total_difference`;