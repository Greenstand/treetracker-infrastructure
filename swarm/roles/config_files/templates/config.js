exports.connectionString = "postgres://{{db_user}}:{{db_pw}}@{{db_host}}/treetracker";

exports.jwtCertificate = "{{jwt_cert}}"

exports.smtpSettings = {
    service: "gmail",
    host: "smtp.gmail.com",
    port: 465,
    secure: true,
    auth: {
        user: "{{email_user}}",
        pass: "{{email_pw}}"
    }
};

exports.api_client_id = "{{api_client_id}}"

exports.api_client_secret = "{{api_client_secret}}"

exports.optimizedBounds = '57.0,9.0,17.0,-16.0'
