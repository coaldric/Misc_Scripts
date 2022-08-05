#------------------------------------------------------------------------------
#
# Copyright © 2022 Microsoft Corporation. All rights reserved.
#
# THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED AS IS WITHOUT
# WARRANTY OF ANY KIND EITHER EXPRESSED OR IMPLIED INCLUDING BUT NOT
# LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
# FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE INABILITY TO USE OR
# RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
#
#------------------------------------------------------------------------------
#
# PowerShell Source Code
#
# NAME:
# trim-SAMaccountname.ps1
#
# VERSION:
# 1.2
#
#------------------------------------------------------------------------------
###With Middle Name###
#double hypen; fml without hyphens + ctr is less than 20 (should result in maggie.a.jane.ctr)
#$UPN            = "maggie-maybelle.a.jane-doe.ctr@mail.mil" 

#single hypen but longer than 20 (should result in maggie.a.doe.ctr) 
#$UPN            = "maggie-maybelle.a.doe.ctr@mail.mil" 

#single hypen but with .ctr still less than 20 (should result in maggie-may.a.doe.ctr) 
#$UPN            = "maggie-may.a.doe.ctr@mail.mil" 

#no hyphen; fml -ctr is more than 20 (should result in maggiema.a.janedonn)
#$UPN            = "maggiemaybelle.a.janedonner.ctr@mail.mil" 

#no hyphen; fml -ctr is less than 20 (should result in maggiemaybe.a.donner)
#$UPN            = "maggiemaybe.a.donner.ctr@mail.mil"

#no hypen; fml + ctr is less than 20 (should result in maggie.a.doe.ctr)
#$UPN            = "maggie.a.doe.ctr@mail.mil" 

###Without Middle Name###

#double hypen (should result in maggie.jane.ctr)
#$UPN            = "maggie-may.jane-doe.ctr@mail.mil" 

#single hypen (should result in maggie.doe.ctr) 
#$UPN            = "maggie-maybelle.doe.ctr@mail.mil" 

#no hyphen; fml -ctr is more than 20 (should result in maggiema.janedonn)
#$UPN            = "maggiemaybelle.janedonner.ctr@mail.mil" 

#no hyphen; fl -ctr is less than 20 (should result in maggiema.donner.ctr)
#$UPN            = "maggiemaybelle.donner.ctr@mail.mil" 

#no middle name; fl + ctr is less than 20 (should result in maggiemay.doe.ctr)
$UPN            = "maggiemay.doe.ctr@mail.mil" 

$SAMsections    = New-Object System.Collections.ArrayList 
$SAM = $UPN.Split("@")
#If SAM is already -le 20 then set $output and be done
if($SAM[0].Length -le 20)
    {
        $output = $SAM[0]        
    }

#If SAM is -ge 21 then continue
if($null -eq $output)
    {
        ##Check for if there is a middle name by counting the (.) periods
        $SAMsplit       = $SAM.Split(".")
        ### 6 = middle name
        if(($SAMsplit).count -eq 6)
            {
            $SAMfirst       = $SAMsplit[0]
            $SAMmiddle      = $SAMsplit[1]
            $SAMlast        = $SAMsplit[2]
            $SAMDesignation = $samsplit[3]
            ####Check to see if First.M.Last -le 20; if it is, set $output and be done
            if(($SAMsplit[0,1,2] -join ".").Length -le 20)
                {
                    $output = $SAMsplit[0,1,2] -join "."
                }

            }
        ### 5 = no middle name
        if(($SAMsplit).count -eq 5)
            {
            $SAMfirst       = $SAMsplit[0]
            $SAMlast        = $SAMsplit[1]
            $SAMDesignation = $samsplit[2]
            ####Check to see if First.Last -le 16; if it is, append .ctr/.mil/.civ and set $output and be done
            if(($SAMsplit[0,1] -join ".").Length -le 16)
                {
                    $output = $SAMsplit[0,1,2] -join "."
                }
            ####Check to see if First.Last is -le 20; if it is then set $output and be done
            elseif(($SAMsplit[0,1] -join ".").Length -le 20)
                {
                    $output = $SAMsplit[0,1] -join "."
                }

            }
        #Does UPN contain a (-) hyphen? If so, we need to separate it to avoid a name ending in a hyphen (maggie-.a.doe.ctr)
        if($UPN -like '*-*')
            {
                ##Check to see if first name has a (-) hyphen
                if($SAMfirst -like '*-*')
                    {
                        $SAMfirst = $SAMfirst.Split("-")
                        $SAMfirst = $SAMfirst[0]
            
                        if($SAMfirst.length -gt 8)
                            {
                                $samsections.add($SAMfirst.substring(0,8)) | out-null}else{$samsections.add($SAMfirst) | out-null
                            }
                    }
                ##If it doesn't, take the first 8 characters of the name
                elseif($SAMfirst.length -gt 8)
                    {
                        $samsections.add($SAMfirst.substring(0,8)) | out-null}else{$samsections.add($SAMfirst) | out-null
                    }
                ##Check to see if there's a middle name; if there is grab the first letter
                if($null -ne $SAMmiddle){
                    if($SAMmiddle.length -gt 1)
                    {
                        $samsections.add($SAMmiddle.substring(0,1)) | out-null}else{$samsections.add($SAMmiddle) | out-null
                    }
                }
                ##Check to see if first name has a (-) hyphen
                if($SAMlast -like '*-*')
                    {
                        $SAMlast = $SAMlast.Split("-")
                        $SAMlast = $SAMlast[0]
                        if ($SAMlast.length -gt 8)
                        {
                            $samsections.add($SAMlast.substring(0,8)) | out-null}else{$samsections.add($SAMlast) | out-null
                        }
                    }
                ##If it doesn't, take the first 8 characters of the name
                elseif($SAMlast.length -gt 8)
                    {
                        $samsections.add($SAMlast.substring(0,8)) | out-null}else{$samsections.add($SAMlast) | out-null
                    }
                ##putting the sections back together to create the trimmed SAM
                ###If there is a middle name
                if($null -ne $SAMmiddle)
                    {
                    $SAMfml     =  $SAMsections[0,1,2] -join "."
                    ####Check to see if f.m.l + .ctr -le 20
                    if($SAMfml.Length -le 16)
                        {
                            $output = "$SAMfml.$SAMDesignation"
                        }
                    ####else just set it to f.m.l
                    elseif($SAMfml.Length -le 20)
                        {
                            $output = $SAMfml 
                        }
                    }
                ###If there is no middle name   
                elseif($null -eq $SAMmiddle)
                    {
                    $SAMfl     =  $SAMsections[0,1] -join "."
                    ####Check to see if f.l + .ctr -le 20
                    if($SAMfl.Length -le 16)
                        {
                            $output = "$SAMfl.$SAMDesignation"
                        }
                    ####else just set it to f.l
                    elseif($SAMfl.Length -le 20)
                        {
                            $output = $SAMfl 
                        }
                    }
            }
        #If there's no (-) hypen AND output is null; that means we have a name thats longer than 20 which we need to trim
        #we'll take the first 8 characters of the first and last names as well as the middle initial if there is on. 
        elseif(($null -eq $output) -and ($UPN -notlike '*-*'))
            {    
                if($SAMfirst.length -gt 8)
                    {
                        $samsections.add($SAMfirst.substring(0,8)) | out-null}else{$samsections.add($SAMfirst) | out-null
                    }
                if($null -ne $SAMmiddle){
                        if($SAMmiddle.length -gt 1)
                        {
                            $samsections.add($SAMmiddle.substring(0,1)) | out-null}else{$samsections.add($SAMmiddle) | out-null
                        }
                    }         
                if ($SAMlast.length -gt 8)
                    {
                        $samsections.add($SAMlast.substring(0,8)) | out-null}else{$samsections.add($SAMlast) | out-null
                    }
                    if($null -ne $SAMmiddle)
                    {
                    $SAMfml     =  $SAMsections[0,1,2] -join "."
                    if($SAMfml.Length -le 17)
                        {
                            $output = "$SAMfml.$SAMDesignation"
                        }
                    elseif($SAMfml.Length -le 20)
                        {
                            $output = $SAMfml 
                        }
                    }
                elseif($null -eq $SAMmiddle)
                    {
                    $SAMfl     =  $SAMsections[0,1] -join "."
                    if($SAMfl.Length -le 16)
                        {
                            $output = "$SAMfl.$SAMDesignation"
                        }
                    elseif($SAMfl.Length -le 20)
                        {
                            $output = $SAMfl 
                        }
                    }           
            }
        }
$output