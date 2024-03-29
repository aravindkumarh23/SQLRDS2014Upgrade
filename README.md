# SQLRDS2014Upgrade
SQL RDS Upgrade from 2014 to higher version

# What this Automation Tool does  ?

When you go through the SQL RDS Major version In Place upgrade journey by following this https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.SQLServer.html , you will need to follow series of manual process in order to perform a successful in place upgrade. For example Copy paramter group,option group and there is no AWS CLI command to perform this task in a automated way.

This process is a single-click deployment that will enable customers perform the task successfully with few user inputs.

## Prerequisites
- AWS CLI latest version
- Python latest version
- Source SQL RDS Instance to upgrade


> **⚠️ Note**
>
>Tool will successfully run  only when compatabile and supported values are passed. For more information , refer to  :https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_SQLServer.html for more information 
>
>If you are trying to enable MultiAZ on RDS for SQL Server 2014 that has MSDTC Option enabled, this will fail since MultiAZ is not supported when MSDTC is enabled.
>
>If you have SSAS enabled on RDS for SQL Server 2014 , if you try to upgrade to on RDS for SQL Server 2022, this will fail as SSAS is not supported in on RDS for SQL Server 2022.
>
>If you have SSRS DB option enabled on the source RDS,make sure to provide permission on the SSRS Secrets's resource policy to the new Option Group name, that you will pass during the script execution (example : SQL-RDS-2022-OG) in Secrets manager. Only then SSRS copy will be successful. For more information, refer to https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.SQLServer.Options.SSRS.html>
>
>If you are running on SQL Server 2014 with MultiAZ  and trying to upgrade to SQL Server 2022 this will fail . As per upgrade path you need to either convert Multi AZ to SingleAZ first or upgrade to intermediate verison before upgrading to 2022. MultiAZ to SingleAZ conversion is not handled by this tool. Once you manually convert them you can rerun this tool.
>
>Make sure to evaluate and remove any paramters that are not needed in the upgraded version . This tool will copy all the parameters from source to target version.
>



## How to Run this ?

All you need to do is , execute this shell script `rds_upgrade.sh` and provide requested inputs. Take a break ! We will take care of the upgrade.

## What does each file do ?

- `rds_upgrade_2014.sh` This is the main file that need to be run for executing the upgrade. 
- `db_options.py` This python file performs json parsing , creates an output that serve as input for option group and parameter group creation. 
- `og_input.json` & `og_output.json` are used to create option group.
- `source_pg.json` file is used to create parameter group.
