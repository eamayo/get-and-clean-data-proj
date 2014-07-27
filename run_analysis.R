# R packages needed
library(plyr)

## Step 0: Download the data
#  * download the zip file from the UCI ML repository and unzip the Samsung 
#    data folder into the working directory.

if (!file.exists("UCI_HAR_Dataset")) {
  fileUrl <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
  download.file(fileUrl, destfile = "UCI_HAR_Dataset.zip", method = "curl")
  
  unzip("UCI_HAR_Dataset.zip")
  file.rename("UCI HAR Dataset", "UCI_HAR_Dataset")
}


## Step  1: Load the relevant data files into R and perform som pre-processing steps

# Step 1a: load the descriptive data - variable names and activity codes to activity name mapping
#  * load activity_labels.txt into a data frame with two variables - "activity_label_code" and 
#    "activity_label_name". This data frame will be used to map activity labels to human readable format.
#  * load features.txt into a data frame. Remove parentheses from the strings in the
#    second column. For example tBodyAcc-mean()-X will become tBodyAcc-mean-X.  Also
#    variable names of the form angle(X,Y..) will get replaced by
#    angle-X,Y e.g  angle(tBodyGyroMean,gravityMean) will become  angle-tBodyGyroMean,gravityMean.
#    This transformed column will be used to label the train and test data sets with
#    descriptive variable names. Note that when passed to the col.names argument of read.table
#    the "-" and "," in the descriptive names will get converted to ".". So for example the variable name
#    angle-tBodyGyroMean,gravityMean will become angle.tBodyGyroMean.gravityMean
label_names <- read.table(
                            "UCI_HAR_Dataset/activity_labels.txt", 
                            header = FALSE, sep = " ",
                            col.names = c("activity_label_code", "activity_label_name"),
                            stringsAsFactors = FALSE
                          )
features <- read.table(
                        "UCI_HAR_Dataset/features.txt", 
                        header = FALSE, sep = " ",
                        col.names = c("feature_num", "feature_name"),
                        stringsAsFactors = FALSE
                      )
features$feature_name <- gsub("\\(|\\)", "", features$feature_name)
features$feature_name <- gsub("angle", "angle-", features$feature_name)
feature_names <- features[,"feature_name"]
numFeatures <- length(feature_names)

## Step1b: create a data frame for the test set
#  * load the test/subject_test.txt, test/X_test.txt and y_test.txt into R (as vector, 
#    data frame and vector respectively)
#  * give X_test variables descriptive names using the feature_names vector generated above
#  * Select only the columns of X_test corresponding to measurements on the mean 
#    and standard deviation for each measurement. 
#  * augment the resulting X_test data frame with an extra variable called "activity_label_code" 
#    using the values loaded from y_test.txt
#  * augment the resulting X_test data frame with an extra variable called "subject" (from the
#    data loaded from subject_test.txt) indicating which subject the measurements in each record 
#    were taken from
#  * join the X_test data frame from above with the label_names data frame using the 
#    "activity_label_code" variable as the join key. The joined data frame now has descriptive 
#    activity label names.
subjects_test <- read.table(
                              "UCI_HAR_Dataset/test/subject_test.txt", 
                              header = FALSE, sep = " ",
                              col.names = c("subject")
                          )

X_test <- read.table(       
                      "UCI_HAR_Dataset/test/X_test.txt", 
                      header = FALSE, 
                      colClasses = "double",
                      col.names = feature_names
                    )
X_test <- X_test[, grepl("mean|std", names(X_test))]

y_test <- read.table(
                      "UCI_HAR_Dataset/test/y_test.txt", 
                      header = FALSE, 
                      col.names = "activity_label_code"
                    )
X_test$activity_label_code <- y_test$activity_label_code
X_test$subject <- subjects_test$subject
test_data <- join(X_test, label_names, by = "activity_label_code")
# we no longer need the activity_label_code variable
test_data <- test_data[, !grepl("activity_label_code", names(test_data))]

## Step1c: repeat the same steps above for the train set data files
subjects_train <- read.table(
                              "UCI_HAR_Dataset/train/subject_train.txt", 
                              header = FALSE, sep = " ",
                              col.names = c("subject")
                            )

X_train <- read.table(       
                      "UCI_HAR_Dataset/train/X_train.txt", 
                      header = FALSE, 
                      colClasses = "double",
                      col.names = feature_names
                    )
X_train <- X_train[, grepl("mean|std", names(X_train))]

y_train <- read.table(
                      "UCI_HAR_Dataset/train/y_train.txt", 
                      header = FALSE, 
                      col.names = "activity_label_code"
                    )

X_train$activity_label_code <- y_train$activity_label_code
X_train$subject <- subjects_train$subject
train_data <- join(X_train, label_names, by = "activity_label_code")
# we no longer need the activity_label_code variable
train_data <- train_data[, !grepl("activity_label_code", names(train_data))]

## Step 2: combine the test and train data frames into a single data frame
all_data <- rbind(train_data, test_data)

## Step 3: generate a new data frame with the average of each variable for each activity and each subject 
tidy_UCI_HAR_dataset <- ddply(all_data, .(subject, activity_label_name), numcolwise(mean))

## Step 4: write the new data frame to disk as a tab-separated text file
write.table(tidy_UCI_HAR_dataset, file = "tidy_UCI_HAR_dataset.tsv", sep = "\t", row.names = FALSE)
