# Intoduction
```SelectKill``` is a simple bash script which interactively and selectively kills a group of processes matching certain pattern.

# Usage
- download the repository
```bash
git clone https://github.com/Gyumeijie/SelectKill.git
```
- cd into the ```SelectKill``` directory, and run the following command
```bash
./install.sh
```
- then you can use the ```SelectKill``` command

## 1. run ```SelectKill``` with a pattern

 ![selection](./assets/selection.png)

As shown above, all the processes match the pattern ```root```, you can use the ```up/down``` keys to select which process
you want to kill.

## 2. select the process which requires root priviledge to kill

 ![sudo_first_time](./assets/sudo_first_time.png)

 may you should try second time:
 
 ![sudo_second_time](./assets/sudo_second_time.png)
 
 again, you can try the last time:
 
 ![sudo_third_time](./assets/sudo_third_time.png)
 
 but if you failed three times, ```SelectKill``` will give you the following message:

 ![permission_denied](./assets/permission_denied.png)

## 3. select the process which you have permission to kill
Say, you have the root priviledge and then you can kill the process with pid equavilent to ```27237```. Maybe you
need to go through some steps talked above--typing your password.

![process_killed](./assets/process_killed.png)

# Settings
The ```SelectKill``` has two regions: ```message region``` and ```options region```. The message region is used to 
display information, say details of long option which is too long to display in the region; and the options region is 
to show information of processes matching the pattern, if one option is too long, we deprecate it at some point and 
replace the deprecated content with ```...``` and when the long option is being selected we display the original information
back in the message region.

## set size for message region and options region

![region](assets/regions.png)

As shown in the picture above, we can customize the size of both region in the ```config.ini``` file.
say we can have message region set to ```4 rows``` and option region to ```5 rows```, the following is the corresponding
setting:
```
  LISTNUM=5
  MSGNUM=4
```

## set the duration of showing instant message

Instant messages like prompting successfully killing a process or denied to kill a process should not be always
shown in message region, so we can give them a duration for displaing, say ```1.5 s```, the following is the corresponding
setting:
```
  SHOW_DURATION=1.5
```

# Todos
- [ ] Prettify processes information shown in the option region.
- [ ] Support refreshing for getting realtime processes information but not a staic snapshot.
- [ ] Add confirming session for killing a process.
