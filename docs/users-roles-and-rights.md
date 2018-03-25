
### Users

First, you'll have to manage a list of users. 

You can create a user with `New-PXUser`, specifying user name and password.


### Roles

Then, you will have to define roles that will give access to one or more features. You cannot restrict access to one or more endpoints inside one feature. If you give access to the feature, it will give access to all the feature's endpoints. 

You can create a role with `New-PXRole`, specifying role name and associated features. Features must be comma separated or you can specify * for all features.


### Rights

Finally, you will associate each user to one or more roles to grant access to features.

You can grant rights with `Grant-PXRight` to associate user to role.

