require 'pry'

CELL_DELIMETER = "   "
DOUBLE_CELL_DELIMETER = "                    "

txt_lines = [
  "Alabama                  140        35           8          26           1         105         33         72                     Rep         Rep          Rep",
  "Alaska                    60        20           6          14                      40         16         23          1          Rep         Ind         Divided",
  "Arizona                   90        30          13          17                      60         24         36                     Rep         Rep          Rep",
  "Arkansas                 135        35          11          24                     100         36         64                     Rep         Rep          Rep",
  "California               120        40          25          12          3v          80         52         28                     Dem         Dem          Dem",
  "Colorado                 100        35          17          18                      65         34         31                     Split       Dem         Divided",
  "Connecticut              187        36          20          15          1v         151         86         63          2v         Dem         Dem          Dem",
  "Delaware                  62        21          12           9                      41         25         16                     Dem         Dem          Dem",
  "Florida                  160        40          14          25          1v         120         38         80          2v         Rep         Rep          Rep",
  "Georgia                  236        56          18          38                     180         59         120         1          Rep         Rep          Rep",
  "Hawaii                    76        25          24           1                      51         44          7                     Dem         Dem          Dem",
  "Idaho                    105        35           7          28                      70         14         56                     Rep         Rep          Rep",
  "Illinois                 177        59          39          20                     118         71         47                     Dem         Rep         Divided",
  "Indiana                  150        50          10          40                     100         30         70                     Rep         Rep          Rep",
  "Iowa                     150        50          26          24                     100         43         56          1v         Split       Rep         Divided",
  "Kansas                   165        40           8          32                     125         28         97                     Rep         Rep          Rep",
  "Kentucky                 138        38          11          26          1v         100         54         46                     Split       Dem         Divided",
  "Louisiana                144        39          13          26                     105         43         56        2, 4v        Rep         Rep          Rep",
  "Maine                    186        35          15          20                     151         78         68        4, 1v        Split       Rep         Divided",
  "Maryland                 188        47          33          14                     141         91         50                     Dem         Rep         Divided",
  "Massachusetts            200        40          34           6                     160         123        35          2v         Dem         Rep         Divided",
  "Michigan                 148        38          11          27                     110         47         63                     Rep         Rep          Rep",
  "Minnesota                201        67          39          28                     134         62         72                     Split       Dem         Divided",
  "Mississippi              174        52          20          32                     122         56         66                     Rep         Rep          Rep",
  "Missouri                 197        34           9          25                     163         44         117        1,1v        Rep         Dem         Divided",
  "Montana                  150        50          21          29                     100         41         59                     Rep         Dem         Divided",
  "Nevada                    63        21          10          11                      42         17         25                     Rep         Rep           Rep",
  "New Hampshire            424        24          10          14                     400         160        238         2          Rep         Dem         Divided",
  "New Jersey               120        40          24          16                      80         48         32                     Dem         Rep         Divided",
  "New Mexico               112        42          25          17                      70         33         37                     Split       Rep         Divided",
  "New York                 213        63          25          33          5           150        105        44          1         Split        Dem        Divided",
  "North Carolina           170        50          15          34          1v          120        45         73        1, 1v       Rep          Rep          Rep",
  "North Dakota             141        47          15          32                      94         23         71                    Rep          Rep          Rep",
  "Ohio                     132        33          10          23                      99         34         65                    Rep          Rep          Rep",
  "Oklahoma                 149        48           8          40                      101        29         72                    Rep          Rep          Rep",
  "Oregon                    90        30          18          12                      60         35         25                    Dem          Dem         Dem",
  "Pennsylvania             253        50          20          30                      203        83         119         1v        Rep          Dem        Divided",
  "Rhode Island             113        38          32           5           1          75         63         11          1         Dem          Dem         Dem",
  "South Carolina           170        46          18          28                      124        46         78                    Rep          Rep          Rep",
  "South Dakota             105        35           8          27                      70         12         58                    Rep          Rep          Rep",
  "Tennessee                132        33           5          28                      99         26         73                    Rep          Rep          Rep",
  "Texas                    181        31          11          20                      150        50         97          3v        Rep          Rep          Rep",
  "Utah                     104        29           5          24                      75         12         63                    Rep          Rep          Rep",
  "Vermont                  180        30          21           9                      150        85         53          12        Dem          Dem         Dem",
  "Virginia                 140        40          19          21                      100        32         67          1         Rep          Dem        Divided",
  "Washington               147        49          24          25                      98         51         47                    Split        Dem        Divided",
  "West Virginia            134        34          16          18                      100        36         64                    Rep          Dem        Divided",
  "Wisconsin                132        33          14          18           1           99         36        63                    Rep          Rep          Rep",
  "Wyoming                   90        30           4          26                       60          9        51                    Rep          Rep          Rep",
]

txt_lines.map!{|line| line.gsub!( line.slice(0,25) , "#{line.slice(0,25).strip}#{CELL_DELIMETER}") }
txt_lines.map!{|line| line.gsub(DOUBLE_CELL_DELIMETER, "#{CELL_DELIMETER}0#{CELL_DELIMETER}")}
txt_lines.each do |line|
  cells = line.split(CELL_DELIMETER).map{|l| l.strip } - [""]
  puts "ROW PARSING ERROR #{line}" unless cells.count == 13
end
