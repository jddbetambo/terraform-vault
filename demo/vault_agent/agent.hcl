# Agent configuration
auto_auth {
    method "approle" {
        config = {
            role_id_file_path = "role.txt"
            secret_id_file_path = "secret.txt"
            remove_secret_id_file_after_reading = false
        }
    }

    sink "file" {
        config = {
            path = "sink.txt"
        }
    }
}

# Vault server configuration
vault {
    address = "http://192.168.1.102:8200"
}

template {
    source = "web.tmpl"
    destination = "output.txt"
    command = "echo 'Template rendered!'"
}