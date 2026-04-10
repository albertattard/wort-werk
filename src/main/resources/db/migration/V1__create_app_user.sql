create table user_entities (
    id           varchar(128) primary key,
    name         varchar(64)  not null unique,
    display_name varchar(128) not null
);

create table user_credentials (
    credential_id                varchar(512) primary key,
    user_entity_user_id          varchar(128) not null,
    public_key                   bytea not null,
    signature_count              bigint not null,
    uv_initialized               boolean not null,
    backup_eligible              boolean not null,
    authenticator_transports     varchar(255),
    public_key_credential_type   varchar(32) not null,
    backup_state                 boolean not null,
    attestation_object           bytea,
    attestation_client_data_json bytea,
    created                      timestamp not null,
    last_used                    timestamp not null,
    label                        varchar(255) not null,
    constraint fk_user_credentials_user_entity foreign key (user_entity_user_id) references user_entities(id) on delete cascade
);

create index idx_user_credentials_user_entity_user_id on user_credentials (user_entity_user_id);
