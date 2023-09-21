CREATE or replace PROCEDURE test3(CheckedPeer varchar, CheckingPeer varchar, task_name varchar, p2p_check_status check_status, time_check time)
language plpgsql

AS $$
declare 
	check_id integer;
begin 
	if not (select exists (select p2p.checkingpeer from p2p where p2p.checkingpeer = CheckingPeer))
	then raise 'not found checkingpeer';
	end if;
	
	if not (select exists (select p2p.checkedpeer from p2p where p2p.checkedpeer = CheckedPeer))
	then raise 'not found checkedpeer';
	
	end if;
	if (p2p_check_status == 'Start') then
		select max(id)+1 from checks into check_id;
		insert into checks(id, peer, task, date)
		values (check_id, CheckedPeer, task_name, current_date);
		
	else
		select checks from p2p where checkingpeer = CheckingPeer and state = 'Start' 
		order by id desc limit 1 into check_id;
		
		if check_is is null then
			raise 'no start status for that checking peer';
		end if;

	end if;
	
	insert into p2p(id, checks, checkingpeer, check_state, created)
	values ((select max(id)+1 from p2p), check_id, CheckingPeer, task_name, current_date);
		

end;
$$;




//// 
CREATE or replace PROCEDURE test4(n integer)
language plpgsql

AS $$
declare
begin 
	insert into teeeest(id, checks, checkingpeer, state, created)
		select * from p2p where id = n;
		
end;
$$;

select * from teeeest

call test4(15);
drop table teeeest
create table teeeest (
	id bigint primary key,
	Checks integer,
	CheckingPeer varchar,
	state check_status,
	created time  
);