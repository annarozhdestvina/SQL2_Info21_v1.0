create table if not exists P2P
(
	id bigint primary key,
	Check bigint primary key,
	Checkingpeer varchar,
	State varchar,
	created  timestamp with time zone not null
    default (current_timestamp at time zone 'UTC'), 
)