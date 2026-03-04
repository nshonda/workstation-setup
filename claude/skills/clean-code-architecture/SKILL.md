---
name: clean-code-architecture
description: "Foundational software engineering principles covering SOLID, design patterns, clean code, clean architecture, and refactoring. Use this skill whenever writing new code, refactoring existing code, designing classes or modules, making structural decisions, or discussing code organization. Also trigger when the user mentions SOLID, DRY, KISS, YAGNI, design patterns, Factory, Strategy, Observer, Builder, Adapter, clean code, clean architecture, hexagonal architecture, coupling, cohesion, dependency injection, abstraction, polymorphism, inheritance vs composition, Law of Demeter, separation of concerns, or any foundational software design topic. This is the most fundamental skill — it underpins all other engineering skills."
---

# Clean Code & Architecture — Senior Engineer Standards

You are a senior engineer who treats code as craft. Every abstraction you create should earn its existence. Every module should have a clear reason to change — and only one. These principles are language-agnostic — apply them idiomatically in whatever stack the project uses.

## SOLID Principles

### S — Single Responsibility Principle (SRP)
A class/module/function should have exactly ONE reason to change.

**Violation:**
```
class UserService
  method createUser(data)        // user persistence
  method sendWelcomeEmail(user)  // email delivery
  method generateReport()        // reporting
```

**Fix:** Split by responsibility.
```
class UserService
  method createUser(data)

class NotificationService
  method sendWelcomeEmail(user)

class ReportService
  method generateReport()
```

**How to check:** Describe what a class does. If you use "and" or "or", it has too many responsibilities.

### O — Open/Closed Principle (OCP)
Open for extension, closed for modification. Add new behavior without changing existing code.

**Violation:**
```
function calculateDiscount(order)
  if order.type == "premium"
    return order.total * 0.20
  else if order.type == "bulk"
    return order.total * 0.15
  else if order.type == "employee"   // Adding this = modifying existing code
    return order.total * 0.30
```

**Fix:** Use polymorphism or strategy pattern.
```
interface DiscountStrategy
  method calculate(total) -> number

class PremiumDiscount implements DiscountStrategy
  method calculate(total) -> total * 0.20

class BulkDiscount implements DiscountStrategy
  method calculate(total) -> total * 0.15

// Adding EmployeeDiscount requires ZERO changes to existing code
```

### L — Liskov Substitution Principle (LSP)
Subtypes must be substitutable for their base types without breaking behavior.

**Violation (classic):**
```
class Rectangle
  method setWidth(w)   -> this.width = w
  method setHeight(h)  -> this.height = h
  method area()        -> this.width * this.height

class Square extends Rectangle
  method setWidth(w)
    this.width = w
    this.height = w   // Breaks parent's contract — caller sets width, height changes too
```

**How to check:** If overriding a method requires weakening preconditions, strengthening postconditions, or throwing unexpected exceptions — LSP is violated.

### I — Interface Segregation Principle (ISP)
Clients should not depend on methods they don't use. Prefer small, focused interfaces over fat ones.

**Violation:**
```
interface Worker
  method work()
  method eat()
  method sleep()

// A Robot implements Worker but can't eat() or sleep()
```

**Fix:**
```
interface Workable  -> method work()
interface Feedable  -> method eat()
interface Restable  -> method sleep()

class Human implements Workable, Feedable, Restable
class Robot implements Workable
```

### D — Dependency Inversion Principle (DIP)
High-level modules should not depend on low-level modules. Both should depend on abstractions.

**Violation:**
```
class OrderService
  constructor()
    this.db = new PostgresDatabase()     // Tightly coupled to Postgres
    this.mailer = new SendGridMailer()   // Tightly coupled to SendGrid
```

**Fix:** Depend on abstractions, inject implementations.
```
class OrderService
  constructor(db: Database, mailer: Mailer)
    this.db = db
    this.mailer = mailer

// Caller decides the implementations
service = new OrderService(
  db: new PostgresDatabase(),
  mailer: new SendGridMailer()
)
```

**This is the most important principle.** It enables testing (inject mocks), flexibility (swap implementations), and clean architecture (dependencies point inward).

## Clean Code Principles

### DRY (Don't Repeat Yourself)
Every piece of knowledge should have a single, authoritative representation. But DRY is about knowledge duplication, not code duplication. Two functions with identical code that represent different business concepts should NOT be merged.

### KISS (Keep It Simple, Stupid)
The simplest solution that works is the best solution. Complexity must be justified by a concrete need, not a hypothetical future requirement.

### YAGNI (You Aren't Gonna Need It)
Don't build abstractions for requirements that don't exist yet. Build for today's needs, refactor when new needs emerge. Premature abstraction is as dangerous as premature optimization.

### Law of Demeter (Principle of Least Knowledge)
A method should only talk to its immediate friends. No long chains.

**Violation:** `order.getCustomer().getAddress().getCity().getZipCode()`

**Fix:** `order.getShippingZipCode()` — tell, don't ask.

### Tell, Don't Ask
Tell objects what to do, don't ask them for data and then make decisions externally.

**Violation:**
```
if user.getSubscription().getPlan().getTier() == "premium"
  user.getSubscription().setFeatureLimit(100)
```

**Fix:**
```
user.upgradeFeatureLimit(100)   // Let the object manage its own state
```

### Composition Over Inheritance
Prefer composing behavior from small, focused objects over inheriting from deep class hierarchies. Inheritance creates tight coupling and fragile base class problems.

**When to use inheritance:** True "is-a" relationships with shared behavior (rare).
**When to use composition:** "has-a" or "uses-a" relationships (most of the time).

```
// Inheritance (fragile)
class AdminUser extends User
class PremiumAdminUser extends AdminUser   // Diamond problem incoming

// Composition (flexible)
class User
  constructor(role: Role, plan: Plan)
    this.role = role
    this.plan = plan
```

### Separation of Concerns
Each module/layer handles one concern. UI doesn't know about database queries. Business logic doesn't know about HTTP. Data access doesn't know about presentation.

### Fail Fast
Validate inputs at boundaries. Throw errors early. Don't let bad data propagate deep into the system where it causes cryptic failures.

### Principle of Least Surprise
Code should behave the way a reasonable developer would expect. If a method named `getUser()` deletes something, that's a violation.

## Design Patterns — When and Why

Patterns are solutions to recurring problems, not decorations. Apply them when you recognize the problem, not preemptively.

### Creational Patterns

**Factory Method** — Delegate object creation to a factory function or method.
Use when: You need to create objects without specifying the exact class. Common in plugin systems, parsers, notification dispatchers.
```
function createNotification(channel)
  match channel
    "email" -> return new EmailNotification()
    "sms"   -> return new SMSNotification()
    "push"  -> return new PushNotification()
```

**Builder** — Construct complex objects step by step.
Use when: Object has many optional parameters or complex construction logic.
```
query = new QueryBuilder()
  .select("name", "email")
  .fromTable("users")
  .where("active = true")
  .orderBy("created_at", "desc")
  .limit(20)
  .build()
```

**Singleton** — Ensure a class has only one instance.
Use when: Shared resource like a connection pool or config.
Caution: Often overused. Prefer dependency injection. Singletons are global state in disguise and make testing harder.

### Structural Patterns

**Adapter** — Make incompatible interfaces work together.
Use when: Integrating third-party libraries, legacy code, or external APIs.
```
class StripePaymentAdapter implements PaymentGateway
  constructor(stripeClient)

  method charge(amount: Money) -> PaymentResult
    response = this.stripeClient.charges.create(
      amount: amount.cents,
      currency: amount.currency
    )
    return new PaymentResult(success: response.status == "succeeded")
```

**Decorator** — Add behavior to objects dynamically without subclassing.
Use when: Cross-cutting concerns like logging, caching, retry, metrics.
```
class CachingRepository implements Repository
  constructor(inner: Repository, cache: Cache)

  method findById(id)
    cached = cache.get("entity:" + id)
    if cached != null
      return cached
    result = inner.findById(id)
    cache.set("entity:" + id, result, ttl: 300)
    return result
```

**Facade** — Simplify a complex subsystem with a unified interface.
Use when: Multiple classes collaborate on a task and clients don't need to know the internals.
```
class OrderFacade
  constructor(inventory, payment, shipping, notification)

  method placeOrder(cart, customer)
    inventory.reserve(cart.items)
    receipt = payment.charge(customer, cart.total)
    tracking = shipping.schedule(cart.items, customer.address)
    notification.sendConfirmation(customer, receipt, tracking)
    return new OrderConfirmation(receipt, tracking)
```

### Behavioral Patterns

**Strategy** — Encapsulate algorithms and make them interchangeable.
Use when: Multiple ways to perform an operation, selected at runtime. (See OCP example above.)

**Observer** — Notify dependents when state changes.
Use when: Event systems, pub/sub, reactive UIs, decoupling side effects.
```
class EventBus
  subscribers = map of eventName -> list of handlers

  method subscribe(eventName, handler)
    subscribers[eventName].add(handler)

  method publish(eventName, data)
    for each handler in subscribers[eventName]
      handler(data)
```

**Command** — Encapsulate a request as an object.
Use when: Undo/redo, queuing operations, macro recording, audit trails.
```
interface Command
  method execute()
  method undo()

class MoveItemCommand implements Command
  constructor(item, fromPosition, toPosition)

  method execute()
    item.moveTo(toPosition)

  method undo()
    item.moveTo(fromPosition)
```

**State** — Object behavior changes based on internal state.
Use when: Complex state transitions (order lifecycle, document workflow, game states). Replaces long if/elif chains on status fields.
```
interface OrderState
  method cancel(order)
  method ship(order)

class PendingState implements OrderState
  method cancel(order) -> order.setState(new CancelledState())
  method ship(order)   -> order.setState(new ShippedState())

class ShippedState implements OrderState
  method cancel(order) -> throw Error("Cannot cancel shipped order")
  method ship(order)   -> throw Error("Already shipped")
```

### Patterns to Avoid Overusing
- **Singleton**: Prefer DI. Singletons hide dependencies and break testing.
- **Abstract Factory**: Often over-engineering. Start with simple factory functions.
- **Visitor**: Rarely needed. Consider pattern matching instead.
- **Template Method**: Inheritance-heavy. Prefer Strategy (composition).

## Clean Architecture

### The Dependency Rule
Dependencies point INWARD. Outer layers depend on inner layers, never the reverse.

```
┌──────────────────────────────────┐
│  Frameworks & Drivers            │  ← HTTP, DB, UI, External APIs
│  ┌──────────────────────────┐    │
│  │  Interface Adapters      │    │  ← Controllers, Gateways, Presenters
│  │  ┌──────────────────┐    │    │
│  │  │  Use Cases        │    │    │  ← Application business logic
│  │  │  ┌────────────┐   │    │    │
│  │  │  │  Entities   │   │    │    │  ← Core domain objects & rules
│  │  │  └────────────┘   │    │    │
│  │  └──────────────────┘    │    │
│  └──────────────────────────┘    │
└──────────────────────────────────┘
```

### Practical Layer Structure
```
src/
├── domain/           # Entities, value objects, domain rules (ZERO external dependencies)
│   ├── entities/
│   ├── value_objects/
│   └── errors/
├── application/      # Use cases, DTOs, port interfaces
│   ├── use_cases/
│   ├── ports/        # Abstract interfaces (Repository, Gateway, etc.)
│   └── dtos/
├── infrastructure/   # Implementations of ports
│   ├── database/     # Repository implementations
│   ├── external/     # Third-party API clients
│   └── messaging/    # Queue implementations
└── presentation/     # HTTP handlers, CLI, GraphQL resolvers
    ├── http/
    └── cli/
```

**The domain layer is the center.** It has NO imports from any other layer. It defines interfaces (ports) that outer layers implement (adapters). This is Hexagonal Architecture / Ports & Adapters.

### When Clean Architecture is Overkill
- Simple CRUD apps with < 5 entities
- Scripts and one-off tools
- Prototypes and MVPs (refactor into it when complexity demands)

Start simple, extract layers when you feel the pain of coupling.

## Refactoring Patterns

### Extract Method
Long function → break into named, focused functions. Each function should be one level of abstraction.

### Replace Conditional with Polymorphism
Long if/elif/switch on types → use polymorphism (Strategy, State pattern).

### Introduce Parameter Object
Function with 5+ related params → group into a data class/struct/object.

### Replace Primitive with Domain Type
`userId: string` → `userId: UserId` — prevents mixing up IDs, adds validation at construction.

### Extract Interface
Class tightly coupled to a dependency → extract an interface, depend on the abstraction.

### When to Refactor
- Before adding a feature (make the change easy, then make the easy change)
- When you see duplication across 3+ places
- When a function exceeds ~30 lines
- When a class has more than one reason to change
- When tests are hard to write (coupling signal)
- NEVER refactor and add features in the same commit

For advanced architectural patterns, domain modeling techniques, and anti-pattern reference, see `references/patterns.md`.