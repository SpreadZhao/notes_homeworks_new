## In Progress

```tasks
tags include TODO
filter by function task.status.name === "In Progress"
sort by start reverse
```

## Pending

```tasks
tags include TODO
filter by function task.status.name === "Pending"
sort by created
sort by filename
```

## Cancelled

```tasks
tags include TODO
filter by function task.status.type === "CANCELLED"
```