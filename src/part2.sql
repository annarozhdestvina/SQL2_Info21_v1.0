-- Write a procedure for adding P2P check

CREATE or replace PROCEDURE test3(CheckedPeer varchar, CheckingPeer varchar, task_name varchar, p2p_check_status check_status, time_check time)
language sql
AS $$
select * from checks;
$$;



////////////////
CREATE or replace PROCEDURE test3(CheckedPeer varchar, CheckingPeer varchar, task_name varchar, p2p_check_status check_status, time_check time)
language plpgsql

AS $$
declare 
	check_id integer;
begin 
	if (p2p_check_status == 'Start') then
		select max(id)+1 from checks into check_id;
		insert into checks(id, peer, task, date)
		values (check_id, CheckedPeer, task_name, current_date);
		
		insert into p2p(id, checks, checkingpeer, check_state, created)
		values ((select max(id)+1 from p2p), check_id, CheckingPeer, task_name, current_date);

	end if;

end;
$$;






/////////////////////////

CREATE or replace PROCEDURE test3(CheckedPeer varchar, CheckingPeer varchar, task_name varchar, p2p_check_status check_status, time_check time)
language plpgsql

AS $$
declare 
	check_id integer;
begin 
	if (p2p_check_status == 'Start') then
		select max(id)+1 from checks into check_id;
		insert into checks(id, peer, task, date)
		values (check_id, CheckedPeer, task_name, current_date);
		
	else
		select checks from p2p where checkingpeer == CheckingPeer and state == 'Start' into check_id;

	end if;
	
	insert into p2p(id, checks, checkingpeer, check_state, created)
	values ((select max(id)+1 from p2p), check_id, CheckingPeer, task_name, current_date);
		

end;
$$;