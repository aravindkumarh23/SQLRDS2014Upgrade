
#Author Aravind Kumar Hariharaputran
#Version 1
#Date : 03/04/2024

########################################################################################## High level Steps##############################################################################################

#Convert singleAz into multi-Az
#Create new parameter group for target version
#Copy the parameters to target parameter group 
#Create new option group for target version
#Copy the options  to target option group
#Perform Inplace upgrade of RDS instance
#Attach the new option group to RDS instance
#Attach the new parameter group to  RDS instance
#Reboot the RDS instance



#Prerequisites
#AWS CLI latest version
#Python latest version
#Source SQL RDS Instance to upgrade
#Note : Tool will   run successfully only when compatabile and supported values are passed. For more information, refer to  :https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_SQLServer.html
#Example if your RDS for SQL Server 2014 has SSAS DB Option enabled, when you try to copy DB Parameters to  RDS for SQL Server 2022, this will fail since SSAS is not supported by RDS for SQL Server 2022.
#If you are trying to enable MultiAZ on RDS for SQL Server 2014 that has MSDTC Option enabled, this will fail since MultiAZ is not supported when MSDTC is enabled.
#If you have SSRS DB option enabled on the source RDS,provide permission on the SSRS Secrets to the new Option Group (target_option_group_name) in Secrets manager. Only then SSRS copy will be successful. For more information, refer to https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.SQLServer.Options.SSRS.html


#############################################################################################################################################################################################################


rm -f upgrade_output.log
date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log
start=`date +%s`

source_db_instance_identifier='rds-upgrade-testing'
region='us-east-2'
source_db_parameter_group_name=''
source_engineversion=''
source_db_parameter_group_family=''

target_db_parameter_group_name='test-upgrade-pg16'
target_db_parameter_group_family='sqlserver-se-16.0'
target_option_group_name='test-upgrade-og16'
target_engine_name='sqlserver-se'
target_major_engine_version='16.00'
target_engine_version='16.00.4095.4.v1'

echo ----------------------------------------------------------------------------------------------------------------------------------------------------
echo ----------------------------------------------------------------------------------------------------------------------------------------------------
echo ----------------------------------------------------------------------------------------------------------------------------------------------------
echo "AWS SQL RDS INPLACE-UPGRADE" | sed  -e :a -e "s/^.\{1,$(tput cols)\}$/ & /;ta" | tr -d '\n' | head -c $(tput cols)  
echo ----------------------------------------------------------------------------------------------------------------------------------------------------
echo ----------------------------------------------------------------------------------------------------------------------------------------------------
echo ----------------------------------------------------------------------------------------------------------------------------------------------------

echo "Enter Source RDS Instance identifier"
read source_db_instance_identifier

echo "Enter Source RDS Instance AWS Region"
read region

echo "Enter RDS Instance target parameter group name"
read target_db_parameter_group_name

echo "Enter RDS Instance target parameter group family(Example:sqlserver-se-15.0)"
read target_db_parameter_group_family

echo "Enter RDS Instance target option group name"
read target_option_group_name


echo "Enter RDS Instance target engine name(Example:sqlserver-se)"
read target_engine_name

echo "Enter RDS Instance target major engine version(Example:15.00)"
read target_major_engine_version

echo "Enter RDS Instance target engine version(Example:15.00.4345.5.v1)"
read target_engine_version


echo "RDS instance's SQL Server Engine before upgrade">>upgrade_output.log 
source_engineversion=`aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --query 'DBInstances[*].EngineVersion'`
source_engineversion=`sed -e 's/^"//' -e 's/"$//' <<<"$source_engineversion"`
echo $source_engineversion>>upgrade_output.log 


echo "If your RDS is SingleAz ,would you like to convert singleAz to multiAz? If so,please ensure to have automatic backup enabled on RDS to proceed (y/n)?"
read answer
case $answer in 
        [yY] ) 
        multiaz=`aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --query 'DBInstances[*].MultiAZ|[0]'`
        echo "Value of MultiAZ is $multiaz">>upgrade_output.log      
            if [ $multiaz == "false" ]; then
                    date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log
                    echo "Converting Single AZ to MultiAZ">>upgrade_output.log  
                    while true
                    do  
                        sleep 30
                        dbstatus=$(aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --query 'DBInstances[*].DBInstanceStatus|[0]')
                        dbstatus=`sed -e 's/^"//' -e 's/"$//' <<<"$dbstatus"`
                        if [ ${dbstatus} == "available" ];then
                            break;
                        else
                            echo "Pease wait DB is not in available state">>upgrade_output.log
                            date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log
                            sleep 30
                        fi
                    done
                    aws rds modify-db-instance --db-instance-identifier $source_db_instance_identifier --multi-az --apply-immediately>/dev/null
                    while true
                    do  
                        sleep 30
                        dbstatus=$(aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --query 'DBInstances[*].DBInstanceStatus|[0]')
                        dbstatus=`sed -e 's/^"//' -e 's/"$//' <<<"$dbstatus"`
                        if [ ${dbstatus} == "available" ];then
                            break;
                        else
                            echo "MultiAZ conversion is in progress . Please wait">>upgrade_output.log
                            date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log
                            sleep 30
                        fi
                    done

                else                 
                    echo "RDS is already multiAZ">>upgrade_output.log
            fi
            ;;
        [nN] ) 
        echo "Continuing the upgrade without AZ conversion">>upgrade_output.log
            ;;

        * ) echo Invalid response. Please try again;;
esac




echo Getting the source parameter group name from RDS instance>>upgrade_output.log 
source_db_parameter_group_name=`aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --region $region --query 'DBInstances[*].DBParameterGroups[].DBParameterGroupName|[0]'`
source_db_parameter_group_name=`sed -e 's/^"//' -e 's/"$//' <<<"$source_db_parameter_group_name"`
echo $source_db_parameter_group_name>>upgrade_output.log 
date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log 

echo Getting the source option group name from RDS instance>>upgrade_output.log 
source_db_option_group_name=`aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --region $region  --query 'DBInstances[*].OptionGroupMemberships[].OptionGroupName|[0]'`
source_db_option_group_name=`sed -e 's/^"//' -e 's/"$//' <<<"$source_db_option_group_name"`
echo $source_db_option_group_name>>upgrade_output.log 
date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log 

default_pg='(default.)' 

if [[ $source_db_parameter_group_name =~ $default_pg ]]; then
    echo 'Default ParameterGroup found on the source. No new ParameterGroup will be created. Continuing..'>>upgrade_output.log 
    else 
    echo "Custom ParameterGroup $source_db_parameter_group_name found on the source.">>upgrade_output.log
    echo "Creating new parameter group $target_db_parameter_group_name for target version">>upgrade_output.log
    aws rds create-db-parameter-group  --db-parameter-group-name $target_db_parameter_group_name  --region $region --db-parameter-group-family $target_db_parameter_group_family --description 'SQL RDS Upgrade ParameterGroup'>/dev/null
    date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log
    echo "Selecting only modified parameters from  the source">>upgrade_output.log
    aws rds describe-db-parameters --db-parameter-group-name $source_db_parameter_group_name --region $region  --query "Parameters[?Source=='user']" --output json>source_pg.json
    echo "Copying the modified parameters to the target">>upgrade_output.log
    aws rds modify-db-parameter-group --db-parameter-group-name $target_db_parameter_group_name --parameters file://source_pg.json
    date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log
fi

default_og='(default.)'

if [[ $source_option_group_name =~ $default_og ]]; then
    echo 'Default OptionGroup found on the source. No new OptionGroup will be created. Continuing..'>>upgrade_output.log
    else 
    echo 'Custom OptionGroup $source_db_option_group_name found on the source.'>>upgrade_output.log
    echo "Creating new Option group $target_option_group_name for target version">>upgrade_output.log
    aws rds create-option-group  --option-group-name $target_option_group_name  --region $region  --engine-name $target_engine_name --major-engine-version $target_major_engine_version --option-group-description 'SQL RDS Upgrade optionGroup'>/dev/null
    date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log  
    echo "Copying the options from the source option group to the target">>upgrade_output.log
    aws rds   describe-option-groups --option-group-name $source_db_option_group_name --region $region  --query "OptionGroupsList[*].Options">og_input.json
    py db_options.py
    aws rds  add-option-to-option-group --option-group-name $target_option_group_name --options file://og_output.json>/dev/null
    date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log

fi

echo "Performing In Place upgrade now">>upgrade_output.log
date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log
while true
 do  
sleep 30
dbstatus=$(aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --query 'DBInstances[*].DBInstanceStatus|[0]')
dbstatus=`sed -e 's/^"//' -e 's/"$//' <<<"$dbstatus"`
    if [ ${dbstatus} == "available" ];then
            break;
        else
            echo "Pease wait DB is not in available state">>upgrade_output.log
            date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log
            sleep 30
    fi
done
aws rds   modify-db-instance --db-instance-identifier $source_db_instance_identifier --engine-version $target_engine_version --db-parameter-group-name $target_db_parameter_group_name  --option-group-name $target_option_group_name --allow-major-version-upgrade --apply-immediately>/dev/null
while true;
do
    sleep 30
    dbstatus=$(aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --query 'DBInstances[*].DBInstanceStatus|[0]')
    dbstatus=`sed -e 's/^"//' -e 's/"$//' <<<"$dbstatus"`
    if [ ${dbstatus} == "available" ];then
        break;
    else
        echo "Upgrade is in progress . Please wait">>upgrade_output.log
        date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log
        sleep 30
    fi
done
echo "Rebooting RDS instance">>upgrade_output.log
aws rds reboot-db-instance --db-instance-identifier $source_db_instance_identifier --region $region>/dev/null
while true;
do
     sleep 30
    dbstatus=$(aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --query 'DBInstances[*].DBInstanceStatus|[0]')
    dbstatus=`sed -e 's/^"//' -e 's/"$//' <<<"$dbstatus"`
    if [ ${dbstatus} == "available" ];then
        break;
    else
        echo "Reboot is in progress . Please wait">>upgrade_output.log
        date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log
        sleep 30
    fi
done

echo "RDS instance's SQL Server Engine after upgrade">>upgrade_output.log 
source_engineversion=`aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --query 'DBInstances[*].EngineVersion'`
source_engineversion=`sed -e 's/^"//' -e 's/"$//' <<<"$source_engineversion"`
echo $source_engineversion>>upgrade_output.log 

echo "Upgrade completed successfully">>upgrade_output.log
end=`date +%s`
expr=$((end-start))
echo 'Execution time in HH MM SS' >>upgrade_output.log
echo $((expr/3600)) $((expr%3600/60)) $((expr%60))>>upgrade_output.log
