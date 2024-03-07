# sqlrdsupgrade
SQL RDS Upgrade from 2014 to higher version

# What this Automation Tool does  ?

When you go through the SQL RDS Major version In Place upgrade journey by following this https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.SQLServer.html , you will need to follow series of manual process in order to perform a successful in place upgrade. For example Copy paramter group,option group and there is no AWS CLI command to perform this task in a automated way.

This process is a single-click deployment that will enable customers perform the task successfully with few user inputs.

## Prerequisites
- AWS CLI latest version
- Python latest version
- Source SQL RDS Instance to upgrade
- `Note` : Tool will   run successfully only when compatabile and supported values are passed. For more information, refer to  :https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_SQLServer.html for more information
Example if 2014 SQL Server RDS has SSAS DB Option enabled, when you try to copy DB Parameters to SQL Server 2022, this will fail since SSAS is not supported by RDS for SQL Server.
If you have SSRS DB option enabled on the source RDS,provide permission on the SSRS Secrets in Secrets manager. For more information, refer to https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.SQLServer.Options.SSRS.html

## How to Run this ?

All you need to do is , execute this shell script `rds_upgrade.sh` and provide requested inputs. Take a break ! We will take care of the upgrade.