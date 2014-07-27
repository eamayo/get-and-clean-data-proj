### Introduction

In this project we process experimental data collected as part of the "Human Activity Recognition Using Smartphone" experiment conducted at the Non Linear Complex Systems Laboratory of the Universita degli Studi di Genova. The goal of the processing is to prepare tidy data for further analysis.
During the experiment each person performed six activities (WALKING, WALKING_UPSTAIRS, WALKING_DOWNSTAIRS, SITTING, STANDING, LAYING) wearing a smartphone (Samsung Galaxy S II) on the waist. The experimental data consists of a set of 561 features calculated from the sensor signals (accelerometer and gyroscope) collected from the smartphone at the waist of each of the subjects as the performed each of the six activities.

### Generating Tidy Data From the Experimental Dataset

An R script called run_analysis.R is provided that does the following. 

    - Merges the training and the test sets to create one data set.
    - Extracts only the measurements on the mean and standard deviation for each measurement. 
    - Uses descriptive activity names to name the activities in the data set
    - Appropriately labels the data set with descriptive variable names. 
    - Creates a second, independent tidy data set with the average of each variable for each activity and each subject. 


The R script accomplishes the above with the steps detailed below:

* First the data is downloaded from [the link provided on the course page] (https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip) and unzipped into the working directory

```R
      if (!file.exists("UCI_HAR_Dataset")) {
        fileUrl <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
        download.file(fileUrl, destfile = "UCI_HAR_Dataset.zip", method = "curl")
        
        unzip("UCI_HAR_Dataset.zip")
        file.rename("UCI HAR Dataset", "UCI_HAR_Dataset")
      }
```

* loads activity_labels.txt into a data frame with two variables - `activity_label_code` and  `activity_label_name1. This data frame will be used to map activity labels to human readable format.

```R
      label_names <- read.table(
                                  "UCI_HAR_Dataset/activity_labels.txt", 
                                  header = FALSE, sep = " ",
                                  col.names = c("activity_label_code", "activity_label_name"),
                                  stringsAsFactors = FALSE
                                )
```                                
                                
* loads features.txt into a data frame. Removes parentheses from the strings in the second column. For example `tBodyAcc-mean()-X` will become `tBodyAcc-mean-X`.  Also variable names of the form `angle(X,Y..)` will get replaced by `angle-X,Y` e.g  `angle(tBodyGyroMean,gravityMean)` will become  `angle-tBodyGyroMean,gravityMean`. This transformed column will be used to label the train and test data sets with descriptive variable names. Note that when passed to the `col.names` argument of `read.table()` the `-` and `,` in the descriptive names will get converted to `.`. So for example the variable name `angle-tBodyGyroMean,gravityMean` will become `angle.tBodyGyroMean.gravityMean`.

```R
      features <- read.table(
                              "UCI_HAR_Dataset/features.txt", 
                              header = FALSE, sep = " ",
                              col.names = c("feature_num", "feature_name"),
                              stringsAsFactors = FALSE
                            )
      features$feature_name <- gsub("\\(|\\)", "", features$feature_name)
      features$feature_name <- gsub("angle", "angle-", features$feature_name)
      feature_names <- features[,"feature_name"]
```
      
*  loads the `test/subject_test.txt`, `test/X_test.txt` and 'test/y_test.txt` into R. Descriptive names are passed into the `col.names` parameter of read.table. Repeat for the corresponding training set data files

```R
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
      y_test <- read.table(
                            "UCI_HAR_Dataset/test/y_test.txt", 
                            header = FALSE, 
                            col.names = "activity_label_code"
                          )  
                          
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
      
      y_train <- read.table(
                            "UCI_HAR_Dataset/train/y_train.txt", 
                            header = FALSE, 
                            col.names = "activity_label_code"
                          )                    
```

* Selects only the columns of `X_test` and `X_train` corresponding to measurements on the mean and standard deviation for each measurement.

```R
      X_test <- X_test[, grepl("mean|std", names(X_test))]
      X_train <- X_train[, grepl("mean|std", names(X_train))]
```
      
* Augments the resulting `X_test` and `X_train` data frames with an extra variable called `activity_label_code` using the values loaded from y_test.txt and y_train.txt.  Also augments  `X_test` and `X_train` with an extra variable called `subject` (from the data loaded from subject_test.txt) indicating which subject the measurements in each record were taken from

```R
      X_test$activity_label_code <- y_test$activity_label_code
      X_test$subject <- subjects_test$subject
      X_train$activity_label_code <- y_train$activity_label_code
      X_train$subject <- subjects_train$subject
```
      
* Joins the `X_test` and `X_train` data frames from above with the `label_names` data frame using the `activity_label_code` variable as the join key. The joined data frame now has descriptive activity label names. The `activity_label_code` can now be discarded   

```R
      test_data <- join(X_test, label_names, by = "activity_label_code")
      test_data <- test_data[, !grepl("activity_label_code", names(test_data))]
      train_data <- join(X_train, label_names, by = "activity_label_code")
      train_data <- train_data[, !grepl("activity_label_code", names(train_data))]
```      
      
* Combines the test and train data frames into a single data frame `all_data`

```R
      all_data <- rbind(train_data, test_data)
```

* Generates a new data frame with the average of each variable for each combination of subject and activity 

```R
      tidy_UCI_HAR_dataset <- ddply(all_data, .(subject, activity_label_name), numcolwise(mean))
```

* Finally the tidy data set is written to disk as a tab-separated text file called `tidy_UCI_HAR_dataset.tsv` 

```R
      write.table(tidy_UCI_HAR_dataset, file = "tidy_UCI_HAR_dataset.tsv", sep = "\t", row.names = FALSE)
```
