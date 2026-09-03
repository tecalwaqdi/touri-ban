# Accounting Rules (V3)

1. **No amount without currency.**
2. **No cross-currency arithmetic.**
3. **Completed ≠ collected** for cash.
4. **status_code** is operational lifecycle; payment fields never invent “مكتملة”.
5. Historical recognition uses stored majors; missing fields → `incomplete` / `derived`, never invented rates.
6. Agent commission basis (canonical contract): percentage of **platform fee (`total_app`)** unless snapshot says otherwise.
7. Settlement may include an order line at most once per party/type.
8. Payment confirm cannot exceed due (server enforced).
9. Feature flags gate all money-moving writes.
10. Unavailable backend → UI **Unavailable**, never fake zero.
11. Wallet balance ≠ trip earnings ≠ settlement outstanding.
12. Company Profit label forbidden until operating expenses exist → use **Platform Net Revenue / Contribution Position**.
