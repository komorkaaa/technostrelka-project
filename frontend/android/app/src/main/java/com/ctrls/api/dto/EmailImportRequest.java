package com.ctrls.api.dto;

public class EmailImportRequest {
    public String email;
    public String password;
    public String imap_server;
    public String mailbox;
    public int limit;
    public boolean use_sample;
    public boolean consent_to_use_password;

    public EmailImportRequest(
            String email,
            String password,
            String imap_server,
            String mailbox,
            int limit,
            boolean use_sample,
            boolean consent_to_use_password
    ) {
        this.email = email;
        this.password = password;
        this.imap_server = imap_server;
        this.mailbox = mailbox;
        this.limit = limit;
        this.use_sample = use_sample;
        this.consent_to_use_password = consent_to_use_password;
    }
}
