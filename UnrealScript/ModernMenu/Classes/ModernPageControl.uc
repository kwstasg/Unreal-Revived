class ModernPageControl extends UMenuPageControl;

function BeforePaint(Canvas C, float X, float Y)
{
	local UWindowTabControlItem Item;
	local float ItemLeft;
	local float ItemHeight;
	local int Row;

	Super.BeforePaint(C, X, Y);
	ItemLeft = 0;
	Row = 0;
	for (Item = UWindowTabControlItem(Items.Next); Item != None;
		Item = UWindowTabControlItem(Item.Next))
	{
		if (ItemLeft > 0 && ItemLeft + Item.TabWidth > TabArea.WinWidth)
		{
			Row++;
			ItemLeft = 0;
		}
		Item.RowNumber = Row;
		Item.TabLeft = ItemLeft;
		Item.TabTop = Row * Item.TabHeight;
		ItemLeft += Item.TabWidth;
		ItemHeight = Item.TabHeight;
	}
	TabArea.TabRows = Row + 1;
	TabArea.WinHeight = TabArea.TabRows * ItemHeight;
}
