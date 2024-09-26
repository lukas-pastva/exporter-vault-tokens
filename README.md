About Vault token exporter
==================

Vault token exporter is a Prometheus exporter

TLDR: Are You using Hashicorp Vault and them tokens expire and You dont know when to expect that horrible situation? Look no further, with our Vault token exporter 3000 You can call now and get it for free! Yes You heard that right! Free of charge! That is 0800-for-free-token-exporter!

Usge
==================

- Preferred way to use is on k8s with binding file
- /vault/secrets/vault-accessors
- the accessors file format is:
    ```
    tokenDescription1:accessor1
    tokenDescription2:accessor2
    ```
- to use metrics, just navigate to port 
- Required ENV var: 
  - VAULT_ADDR - the adress of Hashicorp Vault server
  - ROLE_NAME - The name of the role the pod is using when authneticating towards Vault


License
==================
- This is fully OpenSource tool. Do whatever You want with it :-)
- Apache License, Version 2.0, January 2004

Contact
==================

- E-mail: info@lukaspastva.sk
