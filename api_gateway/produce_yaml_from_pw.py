import bcrypt
import sys
import base64
import hashlib

# sha256 and base64 encode
sha256_pw = hashlib.sha256(sys.argv[1].encode()).hexdigest().encode()
prepared_pw = base64.b64encode(sha256_pw)
adminpw = bcrypt.hashpw(prepared_pw, bcrypt.gensalt())
val_to_b64 = f"""admin:
    hashed_password: "{adminpw.decode()}"
"""
b64ed_value = base64.b64encode(val_to_b64.encode())
print(f'userData: {b64ed_value.decode()}')
