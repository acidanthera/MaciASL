MaciASL Patches
===============

MaciASL can apply patches in a specific format involving regular expressions to ACPI tables.
Single-line comments start with `#`. Patches themselves should be separated by `;`.
Each patch consists of the following case-insentive terms:

- `extent` --- application scheme.
    Valid extents are `into`, `into_all`.
- `scope` --- application scope (ACPI scope).
    Valid scopes are `All`, `DefinitionBlock`, `Scope`, `Method`, `Device`, `Processor`, `ThermalZone`.
- `predicate` ---  precondition for patch application.
    Valid predicates are `label`, `name_adr`, `name_hid`, `code_regex`, `code_regex_not`, `parent_label`,
    `parent_type`, `parent_adr`, `parent_hid`.
- `action` --- patch action (what applied patch should do).
    Valid actions with arguments are `insert`, `set_label`, `remove_entry`, `replace_content`, `replace_matched`, `replaceall_matched`.
    Valid actions without arguments are `remove_entry`, `remove_matched`, `removeall_matched`, `store_%8`,
    `store_%9`.

#### Grammar definition

```
(into|into_all) (All|DefinitionBlock|Scope|Method|Device|Processor|ThermalZone)
[(label|name_adr|name_hid|code_regex|code_regex_not|parent_label|parent_type|parent_adr|parent_hid) <selector>...]
(insert|set_label|replace_matched|replaceall_matched|remove_matched|removeall_matched|remove_entry|replace_content|store_%8|store_%9)
begin <argument> end;
```

#### DOM patches

```
extent into,into_all
scope All,DefinitionBlock,Scope,Method,Device,Processor,ThermalZone
predicate label,name_adr,name_hid,parent_label,parent_type,parent_adr,parent_hid
action insert,set_label,remove_entry,replace_content
```

#### REGEX patches

```
extent into,into_all
predicate code_regex,code_regex_not
action remove_entry,remove_matched,removeall_matched,replace_matched,replaceall_matched,store_%8,store_%9
```

### Examples

1. In order to replace the content of an ACPI method use the following template:

    ```
    into method label <METHOD_NAME> parent_label <ACPI_PATH> remove_entry;
    ```

    For instance, removing the content of a `_DSM` method of a `SAT0` ACPI device:

    ```
    into method label _DSM parent_label SAT0 remove_entry;
    ```

2. In order to add some ACPI code to the path use the following template:

    ```
    into device label <DEVICE_NAME> insert begin <ACPI code> end;
    ```

3. In order to rename a device via ACPI use the following template:

    ```
    into device label <OLD_NAME> set_label begin <NEW_NAME> end;
    into_all all code_regex <OLD_NAME> replaceall_matched begin <NEW_NAME> end;
    ```

    For instance, renaming a `SAT0` with `SATA` ACPI device:

    ```
    into device label SAT0 set_label begin SATA end;
    into_all all code_regex SAT0 replaceall_matched begin SATA end;
    ```
