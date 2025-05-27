Here's a comprehensive `README.md` file in Markdown format for your `asrep_roast.sh` script:

---

# ASREP Roasting Script (`asrep_roast.sh`)

🛡️ **AS-REP Roasting Automation for Active Directory**
This script automates the enumeration of AS-REP roastable user accounts in an Active Directory environment using Impacket's `GetNPUsers.py`. It processes a list of usernames, attempts to retrieve AS-REP hashes without authentication, and logs the findings for offline password cracking.

---

## 📜 Features

* Accepts a custom list of usernames for testing
* Uses Impacket’s `GetNPUsers` for AS-REP roasting
* Validates inputs and checks connectivity
* Logs results and stores hashes in a structured output directory
* Root privilege check included for safe execution

---

## 🚀 Usage

```bash
./asrep_roast.sh -u <users_file> -i <dc_ip> -d <domain>
```

### 🔧 Options

| Option         | Description                                      | Required |
| -------------- | ------------------------------------------------ | -------- |
| `-u`           | Path to file containing usernames (one per line) | ✅        |
| `-i`           | Domain Controller IP address                     | ✅        |
| `-d`           | Domain name (e.g., `example.local`)              | ✅        |
| `-h`, `--help` | Display help message                             | ❌        |

### 📌 Example

```bash
sudo ./asrep_roast.sh -u users.txt -i 10.10.10.192 -d BLACKFIELD.local
```

---

## 📁 Output

All results are saved under the `asrep_outputs` directory:

* **`asrep_hashes.txt`** — Contains extracted AS-REP hashes (for offline cracking)
* **`<timestamp>_asrep_report.txt`** — Detailed execution report
* **`asrep_roast.log`** — Logging file
Note: Make sure, that the user file input does not contain spaces.
---

## ✅ Requirements

* 🧪 Python & Impacket (`GetNPUsers`)

  ```bash
  pip install impacket
  ```
* 🧰 Dependencies:

  * `bash`, `ping`, `nc`, `tee`

---

## 🛑 Notes

* The script must be run as **root**.
* Validates:

  * IP address format
  * File presence
  * Tool availability
  * Domain Controller reachability and Kerberos port (88)

---

## 🔐 What Is AS-REP Roasting?

AS-REP Roasting is a Kerberos attack targeting accounts that **do not require pre-authentication**. The attacker requests a TGT for these users and retrieves an encrypted message (AS-REP) that can be brute-forced offline to recover credentials.

---

## 📚 Reference

* [Impacket GitHub](https://github.com/SecureAuthCorp/impacket)
* AS-REP Roasting Technique: [https://www.hackingarticles.in/](https://www.hackingarticles.in/)

---

## 🧑‍💻 Author

* Scripted by \ElusiveHacker

---

## 📄 License

This project is licensed under the MIT License.

---

Let me know if you'd like a Greek version or if you'd like to include an example hash/cracking tip using `hashcat`.
