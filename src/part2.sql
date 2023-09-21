--1) Write a procedure for adding P2P check


CREATE or replace PROCEDURE addingP2PCheck(PCheckedPeer varchar, PCheckingPeer varchar, task_name varchar, p2p_check_status check_status, time_check time without time zone)
language plpgsql

AS $$
declare 
	check_id integer;
begin 
	if not (select exists (select peers.NickName from peers where peers.NickName = PCheckingPeer))
	then raise 'not found checkingpeer azaza';
	end if;
	
	if not (select exists (select peers.NickName from peers where peers.NickName = PCheckedPeer))
	then raise 'not found checkedpeer aaaaaa';
	end if;
	
	if not (select exists (select tasks.title from tasks where tasks.title = task_name))
	then raise 'not found task_name bebra';
	end if;
	
	
	if (p2p_check_status = 'Start') then
		select max(id)+1 from checks into check_id;
		insert into checks(id, peer, task, date)
		values (check_id, PCheckedPeer, task_name, current_date);
		
	else
		select checks from p2p where p2p.checkingpeer = PCheckingPeer and state = 'Start' 
		order by id desc limit 1 into check_id;
		
		
		select (select checks from p2p where p2p.state = 'Start' and p2p.checkingpeer = PCheckingPeer
		except
		select checks from p2p where p2p.state in ('Failure', 'Success') and p2p.checkingpeer = PCheckingPeer) limit 1
		into check_id;
		
		
		
		if check_id is null then
			raise 'no start status for that checking peer';
		end if;

	end if;
	
	insert into p2p(id, checks, checkingpeer, state, created)
	values ((select max(id)+1 from p2p), check_id, PCheckingPeer, p2p_check_status, time_check);
		

end;
$$;

select cast(current_time as time);

select date_part('hour', 'minute', current_date)
select date_trunc('minute', currenT_TIMESTAMP::timestamp);



call addingP2PCheck( 'Nearache',  'Pararlaf',  'DO4_LinuxMonitoring_v2.0', check_status 'Start', cast('13:15' as time));
call addingP2PCheck( 'Nearache',  'Pararlaf',  'C2_SimpleBashUtils', check_status 'Fuck', cast('13:35' as time));
call addingP2PCheck( 'Nearache',  'Pararlaf',  'C2_SimpleBashUtils', check_status 'Failure', cast('13:35' as time));
call addingP2PCheck( 'Nearache',  'Pararlaf',  'C4_Math', check_status 'Failure', cast('13:35' as time));


call addingP2PCheck( 'Nearache',  'Pararlaf',  'DO4_LinuxMonitoring_v2.0', check_status 'Failure', cast('13:31' as time));




CREATE or replace PROCEDURE test23(PCheckedPeer varchar, PCheckingPeer varchar, task_name varchar, p2p_check_status check_status, time_check time without time zone)
language plpgsql

AS $$
declare 
	check_id integer;
begin 
	if not (select exists (select peers.NickName from peers where peers.NickName = PCheckingPeer))
	then raise 'not found checkingpeer azaza';
	end if;
	
	if not (select exists (select peers.NickName from peers where peers.NickName = PCheckedPeer))
	then raise 'not found checkedpeer aaaaaa';
	end if;
	
	if not (select exists (select tasks.title from tasks where tasks.title = task_name))
	then raise 'not found task_name bebra';
	end if;
	
	
	if (p2p_check_status = 'Start') then
		select max(id)+1 from checks into check_id;
		insert into checks(id, peer, task, date)
		values (check_id, PCheckedPeer, task_name, current_date);
		
	else
		select checks from p2p where p2p.checkingpeer = PCheckingPeer and state = 'Start' 
		order by id desc limit 1 into check_id;
		
		
-- 		select (select checks from p2p where p2p.state = 'Start' and p2p.checkingpeer = PCheckingPeer
-- 		except
-- 		select checks from p2p where p2p.state in ('Failure', 'Success') and p2p.checkingpeer = PCheckingPeer) 
-- 		into check_ids;
		
		
		if (
		(with cte as
		(select checks from p2p where p2p.state = 'Start' and p2p.checkingpeer = 'Pararlaf'
		except
		select checks from p2p where p2p.state in ('Failure', 'Success') and p2p.checkingpeer = 'Pararlaf')
		select count(*) from cte) > 1) then
		
-- 		if ((select count(*) from cte) > 1) then

			raise 'too many starts';
		else
			select * from cte into check_id
		end if;
		
	
		if check_id is null then
			raise 'no start status for that checking peer';
		end if;

	end if;
	
	insert into p2p(id, checks, checkingpeer, state, created)
	values ((select max(id)+1 from p2p), check_id, PCheckingPeer, p2p_check_status, time_check);
	
end;
$$;