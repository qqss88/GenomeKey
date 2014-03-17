#!/bin/bash

# $1:: list
# $2:: output bucket
# $3:: port
# (respectively name, user and password::$4 $5 $6)
# $7:: cosmos paths (temp and output)
# $8:: server name

# Step 0) Make an output dir

mkdir $8/Out/"$1"

# Step 1) Launch the run

genomekey bam -n "$1" -il $1  #### Here we still need to test if the run was successful or not

# Step 2) Dump the DB (the username and the password are hard-coded here)

mysqldump -u $5 -p $6 –no-create-info $4 > ~/Out/"$1".sql

# Step 3) Reset cosmos DB

cosmos resetdb

# Step 4) Copy files to S3

  #cp the DB
  aws s3 cp $8/Out/"$1"/ $2/"$1"/

  #cp the VCF
  aws s3 cp $8/cosmos/out/stage_name/.../annotated.vcf $2/"$1"/

# Step 5) Clean-up
if [$8 -eq orchestra]; then
    rm -R $8/cosmos/out/*
    rm -R $8/cosmos/tmp/*
else
    rm -R $8/cosmos_out/*
    rm -R $8/cosmos/erik/*
fi

rm $8/Out/*
