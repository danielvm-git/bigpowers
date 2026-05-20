# John Ousterhout Reference: A Philosophy of Software Design

**Source:** [A Philosophy of Software Design](https://www.amazon.com/Philosophy-Software-Design-John-Ousterhout/dp/1732102201)
**Author:** John Ousterhout

## Core Concepts
- **Deep Modules:** Modules should have a simple interface but provide a lot of functionality (low surface area, high internal complexity).
- **Information Hiding:** Modules should hide as much complexity as possible from their users.
- **Complexity is Incremental:** Software systems become complex one small mistake at a time.
- **Define Errors Out of Existence:** Design APIs so that error cases are naturally handled or impossible to trigger.
