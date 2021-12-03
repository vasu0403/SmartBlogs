// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity >=0.4.22 <0.9.0;

contract SmartBlogs {

	enum BlogType {PAID, UNPAID}

	struct Blog {
		uint blogId;
		string blogTitle;
		string blogContent;
		BlogType paid;
		uint value;
		address payable ownerId;
	}

	struct BlogTitle {
		uint blogId;
		string blogTitle;
		BlogType paid;
		uint value;
		address ownerId;
	}


	uint blogCounter = 0;
	// @dev address of the person who is the owner of a blog
	mapping(uint => address) owners;
	// @dev addresses of the viewers who have viewed a particular blog
	mapping(uint => address[]) viewers;
	// @dev list of blogs which each person has viewed - paid or unpaid
	mapping(address => Blog[]) myPaidBlogs;
	// @dev list of blogs which each person has added
	mapping(address => Blog[]) myOwnedBlogs;

	// @dev list of all the blogs posted
	Blog[] private blogs;

	modifier onlyOwner(uint blogId) {
		require(
			owners[blogId] == msg.sender,
			"You are not the owner of this blog"
		);
		_;
	}

	function addBlog(string memory blogTitle, string memory blogContent, uint value) public {
		Blog memory blog = Blog(blogCounter, blogTitle, blogContent, value == 0 ? BlogType.UNPAID : BlogType.PAID, value, msg.sender);
		owners[blogCounter] = msg.sender;
		myOwnedBlogs[msg.sender].push(blog);
		blogs.push(blog);
		blogCounter++;
	}

	function listBlogs() public view returns (BlogTitle[] memory) {
		BlogTitle[] memory blogsWithOnlyTitles = new BlogTitle[](blogs.length);
		for(uint i = 0; i < blogs.length; i++) {
			BlogTitle memory blogWithOnlyTitle = BlogTitle(blogs[i].blogId, blogs[i].blogTitle, blogs[i].paid, blogs[i].value, blogs[i].ownerId);
			blogsWithOnlyTitles[i] = blogWithOnlyTitle;
		}
		return blogsWithOnlyTitles;
	}

	function listFreeBlogs() public view returns (BlogTitle[] memory) {
		uint numFreeBlogs = 0;
		for(uint i = 0; i < blogs.length; i++) {
			if(blogs[i].value != 0) {
				numFreeBlogs++;
			}
		}
		BlogTitle[] memory blogsWithOnlyTitles = new BlogTitle[](numFreeBlogs);
		uint index = 0;
		for(uint i = 0; i < blogs.length; i++) {
			if(blogs[i].value == 0) {
				blogsWithOnlyTitles[index++] = BlogTitle(blogs[i].blogId, blogs[i].blogTitle, blogs[i].paid, blogs[i].value, blogs[i].ownerId);
			}
		}
		return blogsWithOnlyTitles;
	}

	function payForBlog(uint blogId) public payable {
		bool flag = false;
		for(uint i = 0; i < myPaidBlogs[msg.sender].length; i++) {
			if(blogId == myPaidBlogs[msg.sender][i].blogId) {
				flag = true;
				break;
			}
		}
		require(
			flag == false,
			"You have already paid for this blog !"
		);

		require(
			msg.value == blogs[blogId].value,
			"Sent amount should be equal to blog price !"
		);
		
		viewers[blogId].push(msg.sender);
		myPaidBlogs[msg.sender].push(blogs[blogId]);

		address payable ownerAddress = blogs[blogId].ownerId;
		ownerAddress.transfer(blogs[blogId].value);
	}

	function viewBlog(uint blogId) public view returns (Blog memory) {
		if(blogs[blogId].value == 0) {
			return blogs[blogId];
		}

		bool flag = false;
		for(uint i = 0; i < myPaidBlogs[msg.sender].length; i++) {
			if(blogId == myPaidBlogs[msg.sender][i].blogId) {
				flag = true;
				break;
			}
		}
		require(
			flag, "You have not paid for this blog !!!"
		);

		return blogs[blogId];
	}

	function getBlogsPaidFor() public view returns (Blog[] memory) {
		return myPaidBlogs[msg.sender];
	}

	function getOwnedBlogs() public view returns (Blog[] memory) {
		return myOwnedBlogs[msg.sender];
	}

	function getBlogViewers(uint blogId) public view onlyOwner(blogId) returns(address[] memory) {
		return viewers[blogId];
	}

	constructor() public {
	}
}
