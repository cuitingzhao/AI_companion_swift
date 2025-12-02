# Flow:
1. We should prompt a wizard page to ask user "以下里程碑的截止日期已到，请确认该目标是否已达成？" with all the overdued milestone's detail listed and below each milestone desc, there are two options '达成' and '未达成' (align to the right). And one button floating at the bottom of the page "下一步". Only all feedback are provided, do we allow 下一步 to be clickable.
2. If user selects '达成' for all the milestones, then we go to the milestone completed page in the wizard which says '太棒了！你离达成目标又近了一步，加油呀！' with a button '返回', clicking it will bring user back to the home page.
3. If user selects '未达成' for any of the milestones, then we go to the page in the wizard with the unfufilled milestone and saying '没关系，你是否想延续这些里程碑计划？' with two options "重新开始" and "跳过" below each milestone.  If user selects 重新开始 of a milestone, we will pop up a dialog to let user choose a new due date. A '保存' button floats at the bottom of the page. Clicking the 保存 will reset the milestone's due date and set it to active (think we already have the api) and bring user back to the homepage with a toast ("里程碑已重新激活，相关的小任务也会在合适的时间重新开始，这次要加油哦！")

# API for reopen with new date
The backend has enhanced the api /api/v1/goals/milestones/{milestone_id}. You can refer to the line 278 - 356 in @goals.md

# "不用了" behavior
We currently don't need to do anything about it. 
