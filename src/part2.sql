-- Write a procedure for adding P2P check

CREATE or replace PROCEDURE test23(PCheckedPeer varchar, PCheckingPeer varchar, task_name varchar, p2p_check_status check_status, time_check time)
language plpgsql

AS $$
declare 
	check_id integer;
begin 
	if not (select exists (select p2p.checkingpeer from p2p where p2p.checkingpeer = PCheckingPeer))
	then raise 'not found checkingpeer azaza';
	end if;
	
	if not (select exists (select p2p.checkedpeer from p2p where p2p.checkedpeer = PCheckedPeer))
	then raise 'not found checkedpeer lol';
	
	end if;
	if (p2p_check_status == 'Start') then
		select max(id)+1 from checks into check_id;
		insert into checks(id, peer, task, date)
		values (check_id, PCheckedPeer, task_name, current_date);
		
	else
		select checks from p2p where p2p.checkingpeer = PCheckingPeer and state = 'Start' 
		order by id desc limit 1 into check_id;
		
		if check_is is null then
			raise 'no start status for that checking peer';
		end if;

	end if;
	
	insert into p2p(id, checks, checkingpeer, check_state, created)
	values ((select max(id)+1 from p2p), check_id, PCheckingPeer, task_name, current_date);
		

end;
$$;