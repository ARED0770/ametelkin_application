# Метелкин Артём - "Автоматизированный Обменник Валюты"

### Группа: 10 - Э - 2
### Электронная почта: metelkin70@mail.ru
### VK: https://vk.com/id511296143


### [ Сценарий 1 - Регистрация пользователя ]

1. Пользователь вводит логин, с которым он будет заходить в систему
2. Пользователь вводит пароль, с которым он будет заходить в систему
3. Пользователь вводит адрес электронной почты, который будет использоваться в системе
4. Если выбранный логин уже существует в системе, то пользователю сообщается об этом и предлагается придумать новый логин
6. Если пароль содержит менее 6 символов, система сообщает, что пароль должен быть от 6 до 30 символов и пользователь должен придумать новый пароль
7. Если введённый адрес электронной почты не соответствует формату, то система выводит сообщение об ошибке и просит ввести адрес ещё раз
8. Если все введённые данные соответствуют требованиям регистрации, то система отправляет на почту письмо для подтверждения почты
9. После подтверждения имейла система приветствует пользователя и переходит к редактированию профиля и настройкам.

### [ Сценарий 2 - Настройка профиля]

1. Пользователь заходит в настройки.
2. Пользователь вводит ключ API для биржи OKX.
3. Пользователь вводит секретный ключ.
4. Пользователь вводит пасс-фразу.
5. Пользователя выкидывает на основную страницу, после чего он может начинать пользоваться приложением в полном объёме.

### [ Сценарий 5 - Оформление заказа на обмен валюты по рынку ]

1. Пользователь заходит в раздел торговли и выбирает опцию "Рыночный ордер".
3. Вводит сумму, которую желает обменять.
4. Система отображает текущий курс обмена и рассчитывает итоговую сумму с учетом комиссии.
5. Пользователю предлагается подтвердить детали заказа перед финализацией операции.
6. После подтверждения, система проверяет наличие необходимой суммы на счете пользователя.
7. Если средства достаточны, происходит операция обмена, и система отправляет уведомление об успешном выполнении.
8. Система отправляет подтверждение транзакции на электронную почту пользователя.
9. Пользователь может просмотреть историю операций в своем профиле для контроля своих финансов.

### [ Сценарий 6 - Торговля с использованием лимитных ордеров ]

1. Пользователь заходит в раздел торговли и выбирает опцию "Лимитный ордер".
2. Пользователь выбирает валютную пару, по которой он хочет провести торговлю.
3. Вводит количество валюты, которое он хочет купить или продать.
4. Пользователь устанавливает желаемую цену покупки или продажи (лимитную цену).
5. Система отображает предварительный расчет комиссии и итоговую стоимость операции с учетом указанного лимита.
6. Пользователю предлагается проверить и подтвердить все детали ордера перед его размещением.
7. После подтверждения, система регистрирует ордер и ставит его в очередь на выполнение при достижении указанной цены.
8. Система постоянно мониторит рыночные цены и автоматически исполняет ордер при соответствии рыночной цены лимитной цене ордера.
9. После исполнения ордера, пользователь получает уведомление по электронной почте и/или через приложение о статусе ордера.
10. В профиле пользователя обновляется информация о составе портфеля после исполнения торговой операции.
11. Пользователь может просмотреть историю своих ордеров, включая активные, выполненные и отмененные, для анализа и управления своими инвестициями.

### [ Сценарий 7 - Просмотр и анализ валютного портфеля ]

1. Пользователь переходит в раздел "Мой портфель" в приложении.
2. Система отображает обзор текущего состава портфеля с разделением по валютам.
3. Пользователь выбирает валюту для просмотра истории транзакций и аналитических данных.
4. Система предоставляет графики и динамику изменения стоимости выбранной валюты за выбранный период.
5. Пользователь устанавливает параметры уведомлений для получения оповещений о значимых изменениях курсов.
6. При желании, пользователь может переходить к просмотру подробной аналитики по техническим индикаторам.
7. Система предлагает сохранение настроек аналитики для быстрого доступа в будущем.
8. Пользователь может добавлять или удалять валюты из своего портфеля через интерфейс управления.
9. Система обеспечивает возможность экспорта данных портфеля для внешнего анализа и хранения.
