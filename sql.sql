```sql
-- Weapon Fire Mode Switch Items for ox_inventory
-- Run this SQL to add the items to your database

INSERT INTO `items` (`name`, `label`, `description`, `weight`, `stack`, `close`, `allowArmed`, `usable`, `image`) VALUES
('switch_auto', 'Automatic Switch', 'Converts a semi-automatic weapon to fire automatically. Use while holding a weapon.', 100, 0, 1, 0, 1, 'switch_auto.png'),
('remove_switch', 'Switch Remover', 'Removes the automatic switch from a weapon. Use while holding a weapon.', 100, 0, 1, 0, 1, 'remove_switch.png')
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `description` = VALUES(`description`);
```