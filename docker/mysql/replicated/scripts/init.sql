use `mydb`;

set names 'utf8mb4';
set foreign_key_checks = 0;
    
drop table if exists `person`;
drop table if exists `_person`;

create table `person` (
    `id` int unsigned not null auto_increment,
    `_v` int unsigned not null default 1,
    
    `family_name` varchar(50) not null,
    `given_name` varchar(50) null default null,
    `middle_name` varchar(50) null default null,
    
    `created` datetime not null default current_timestamp(),
    `updated` datetime not null default current_timestamp() on update current_timestamp(),
    `deleted` datetime default null,
    
    primary key (`id`)
) engine=innodb;

create table `_person` (
    `id` int unsigned not null,
    `_v` int unsigned not null,
    
    `family_name` varchar(50) default null,
    `given_name` varchar(50) default null,
    `middle_name` varchar(50) default null,
    
    `created` datetime not null,
    `updated` datetime not null,
    `deleted` datetime null,
    
    primary key (`id`, `_v`)
) engine=innodb;

delimiter //

create trigger `person_before_update` before update on `person` for each row begin
    set new.`_v` = old.`_v` + 1;
end //
create trigger `person_after_update` after update on `person` for each row begin 
    insert into `_person` (`id`, `_v`, `family_name`, `given_name`, `middle_name`, `created`, `updated`, `deleted`)
    values (old.`id`, old.`_v`, old.`family_name`, old.`given_name`, old.`middle_name`, old.`created`, old.`updated`, old.`deleted`);
    
    if new.`deleted` is not null and old.`deleted` is null then
        update `_person` set `deleted` = new.`deleted` where `id` = old.`id`;
    end if;
    
    if new.`deleted` is null and old.`deleted` is not null then
        update `_person` set `deleted` = null where `id` = old.`id`;
    end if;
end //
create trigger `person_before_delete` before delete on `person` for each row begin
    if @allow_deletion is null or @allow_deletion = false then
        signal sqlstate '45000'
        set message_text = 'Records in this table cannot be deleted. Set the `deleted` date to the current date instead.';
    end if;
end //
create trigger `person_after_delete` after delete on `person` for each row begin 
    set @allow_deletion = false;
end //

delimiter ;

set foreign_key_checks = 1;

insert into `person` (`id`, `family_name`, `given_name`, `middle_name`)
values (1, 'Roßegger', 'Steffi', null),
       (2, 'Serbe', 'Alex', null),
       (3, 'Paulus', 'Michael', null);

set @allow_deletion = true;
delete from `person` where `id` = 3;
delete from `person` where `id` = 2;
