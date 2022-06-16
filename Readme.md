**Домашнє завдання до лекції №8 курсу Solidity For Beginners**

***Імплементувати контракт-лотерею, що відповідає наступним умовам***
1. Нові лотереї мають створюватись через фабрику. Створення можливе тільки власником фабрики. Фабрика має зберігати адреси всіх лотерей, що були нею створені.
2. Контракт лотереї має мати 3 стани: NEW, IN_PROGRESS, FINALIZING_RESULTS, FINISHED. Кожен з цих станів визначається певним періодом часу, що вказується при створенні контракту.
3. В стані NEW купувати квитки неможливо.
4. В стані IN_PROGRESS користувачі можуть купувати квитки. Кожен користувач може купити до 10 квитків. Всі 10 квитків можуть бути куплені однією транзакцією.
5. Кожен квиток має фіксовану ціну в коінах (ETH). Ціна вказується при створенні контракту.
6. За кожен квиток користувач отримує одне випадкове число від 1 до 1000
7. В стані FINALIZING_RESULTS відбувається підрахунок підсумків лотереї. Перехід у наступний стан можливий тільки після повної обробки результатів.
8. Після переходу контракту в стан FINISHED, власник фабрики має можливість вивести рівно 10% коштів, що були зібрані. 
9. Решта коштів мають бути розділені між користувачами, яким випало найбільше випадкове число.

****Зовншіня частина oracle в завдання не входить****

***Буде плюсом:***
1. Налаштувати оточення для розробки (Truffle, Hardhat, etc).
2. Покрити функціонал фабрики та лотереї тестами.
