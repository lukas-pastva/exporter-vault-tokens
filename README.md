About Exporter Vault tokes
==================

Exporter Vault tokens is a Prometheus exporter

TLDR: Are You using Hashicorp Vault and them tokens expire and You dont know when to expect that horrible situation? Look no further!

Usage
==================

- Preferred way to use is on k8s with binding file
- /vault/secrets/vault-accessors
- the accessors file format is:
```yaml
tokens:
  - name: tokenDescription1
    accessor: accessor1
  - name: tokenDescription2
    accessor: accessor2
  # Add more tokens as needed

```
- to use metrics, just navigate to port 
- Required ENV var: 
  - VAULT_ADDR - the adress of Hashicorp Vault server
  - ROLE_NAME - The name of the role the pod is using when authneticating towards Vault

Contact
==================

- E-mail: info@lukaspastva.sk
