-- project task
use librarymanagement;


-- Task 1. Create a New Book Record 

select * from books;

INSERT INTO books (isbn, book_title, category, rental_price, status , author , publisher) 
values ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

-- Task 2: Update an Existing Member's Address

select * from members;

update members set member_address = '109 tvk st' where member_id = 'C107'; 

-- Task 3: Delete a Record from the Issued Status Table**
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.

select * from issued_status;

delete from issued_status where issued_id = 'IS121';

-- Task 4: Retrieve All Books Issued by a Specific Employee
-- Objective: Select all books issued by the employee with emp_id = 'E101'.

select * from issued_status;
select * from employee;
select issued_book_name from issued_status where issued_emp_id = 'E101';

-- Task 5: List Members Who Have Issued More Than One Book
-- Objective: Use GROUP BY to find members who have issued more than one book.

select * from issued_status;

select issued_emp_id ,count(*) from issued_status 
group by issued_emp_id
having count(*) > 1 
order by count(*);

-- Task 6: Create Summary Tables**: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt

select * from issued_status;
select * from books;

create table book_issued_cnt as 
select b.isbn, b.book_title , count(i.issued_id) as book_count from books as b
inner join issued_status as i
on b.isbn = i.issued_book_isbn
group by i.issued_id, b.isbn;

select * from book_issued_cnt;

-- Task 7. Retrieve All Books in a Specific Category

select * from books
where category = 'classic';

-- Task 8: Find Total Rental Income by Category

select b.category,sum(b.rental_price) as total_rental_price from books as b inner join 
issued_status as i
on b.isbn = i.issued_book_isbn
group by b.category;

select category,sum(rental_price) as total_rental_price from books group by category;

-- Task 9. List Members Who Registered in the Last 180 Days

select * from members;
insert into members values ('C201', 'Alen', '243 Raja st', '2024-12-29');

select * from members where reg_date >= current_date() - interval 180 day;

-- Task 10.List Employees with Their Branch Manager's Name and their branch details

select * from branch;
select * from employee;

select e.emp_id ,e.emp_name, b.branch_id, b.manager_id from branch as b inner join 
employee as e 
on e.branch_id = b.branch_id
join
employee as e1
on e1.emp_id = b.manager_id;

-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold

create table expensive_books as
select book_title, category, rental_price from books
where rental_price > 7.0
order by rental_price;

-- Task 12: Retrieve the List of Books Not Yet Returned

select * from returnstatus;
select * from issued_status;

select * from issued_status as i
left join
returnstatus as r
on i.issued_id = r.issued_id
where r.return_id is null;

-- Task 13: Identify Members with Overdue Books 
-- Write a query to identify members who have overdue books (assume a 25-day return period). 
-- Display the member's_id, member's name, book title, issue date, and days overdue.

select * from members;

select i.issued_member_id, 
m.member_name, b.book_title, 
i.issued_date, r.return_date, 
datediff( '2024-04-23', i.issued_date) as over_due
from members as m
inner join issued_status as i
on m.member_id = i.issued_member_id
join
books as b
on b.isbn = i.issued_book_isbn
left join returnstatus as r
on r.issued_id = i.issued_id
where r.return_date is null 
and
datediff( '2024-04-23', i.issued_date) >= 25
order by 1;

-- Task 14: Update Book Status on Return**  
-- Write a query to update the status of books in the books table to "Yes" when 
-- they are returned (based on entries in the return_status table).

select * from books;
select * from issued_status;

update books
set status = 'no' where isbn = '978-0-09-957807-9';
select * from returnstatus;
select * from returnstatus where return_book_isbn = '978-0-09-957807-9';

delimiter //
create procedure return_book(in i_return_id varchar(10),in i_issued_id varchar(10))
begin
declare v_isbn varchar(20);
declare v_id varchar(10);
insert into returnstatus(return_id, issued_id, return_date)
values (i_return_id, i_issued_id, current_date());

select issued_id , issued_book_isbn into v_id, v_isbn from issued_status limit 1;

update books set status = 'yes' where v_id = i_issued_id;
end //
delimiter ;
drop procedure return_book;
call return_book('RS102', 'IS106');


-- Task 15: Branch Performance Report  
-- Create a query that generates a performance report for each branch, showing the number of books issued, 
-- the number of books returned, and the total revenue generated from book rentals.

select * from books;
select * from branch;
select * from issued_status;

create table performance_report as 
select b.branch_id , b.manager_id, count(i.issued_id) as no_book_issued, 
count(r.return_id) as no_book_returned, sum(bk.rental_price) as tot_revenue
from issued_status as i 
inner join
employee as e
on i.issued_emp_id = e.emp_id
inner join
branch as b
on b.branch_id = e.branch_id
left join returnstatus as r
on r.issued_id = i.issued_id
join books as bk
on bk.isbn = i.issued_book_isbn
group by 1;

select * from performance_report;

-- Task 16: CTAS: Create a Table of Active Members**  
-- Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at 
-- least one book in the last 2 months.

select * from issued_status
where issued_date > '2024-03-23';

create table active_members as 
select * from members
where member_id in 
(select distinct issued_member_id from issued_status
where issued_date > '2024-03-23');


select * from active_members;


-- Task 17: Find Employees with the Most Book Issues Processed**  
-- Write a query to find the top 3 employees who have processed the most book issues. 
-- Display the employee name, number of books processed, and their branch.

select * from employee;
select * from branch;
select * from issued_status;  

select e.emp_id, e.emp_name ,b.branch_id, count(i.issued_emp_id) as issued_book_count from issued_status as i
inner join employee as e
on e.emp_id = i.issued_emp_id
inner join branch as b
on e.branch_id = b.branch_id
group by 1,2;

-- Task 19: Stored Procedure**
-- Objective:Create a stored procedure to manage the status of books in a library system.

select * from books;

delimiter //
create procedure manage_books (in i_isbn varchar(20),in i_issued_id varchar(10),
in i_issued_member_id varchar(20),in i_issued_emp varchar(20)) 
begin

declare v_status varchar(10);
declare v_title varchar(50);

select status, book_title into v_status, v_title from books
where isbn = i_isbn;

if v_status = 'yes' then
		insert into issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id) values
        (i_issued_id, i_issued_member_id, current_date(), i_isbn, i_issued_emp);
        update books set status = 'no' where isbn = i_isbn;
end if;
end //
delimiter ;

drop procedure manage_books;

call manage_books('978-0-7432-4722-4','I155','C108','E105');
select * from issued_status;
select * from books as b 
left join 
issued_status as i
on b.isbn = i.issued_book_isbn;

