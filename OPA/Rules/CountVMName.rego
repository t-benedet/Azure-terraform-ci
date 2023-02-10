package main

deny[resource.values.name] {
    some resource
    all_resource[resource]
    regex.match("virtual_machine", resource.type)
    count(resource.values.name) != 13
}


all_resource[resource] {
    resource := input.planned_values.root_module.resources[_]
}
